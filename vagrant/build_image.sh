#!/usr/bin/env bash
# ==============================================================================
# Vagrant Box(이미지) 생성 및 패키징 스크립트
# ==============================================================================
# 설명:
#   지정된 Vagrant VM의 상태를 패키징하여 재사용 가능한 커스텀 .box 이미지로
#   내보냅니다. (옵션으로 KISA 하드닝 플레이북 선행 적용 가능)
#
# 사용법:
#   bash vagrant/build_image.sh ubuntu22               # ubuntu22 기본 박스 패키징
#   bash vagrant/build_image.sh al2023                 # al2023 기본 박스 패키징
#   APPLY_HARDENING=1 bash vagrant/build_image.sh rocky9 # 하드닝 적용 후 패키징
#   bash vagrant/build_image.sh all                    # 전체 VM 순차 패키징
#
# 환경변수:
#   APPLY_HARDENING=1 (또는 true) : 패키징 전 KISA 하드닝 적용 플레이북 실행
#   OUTDIR="images"               : 박스 출력 디렉토리 (기본값: vagrant/images)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET="${1:-${DISTRO:-}}"
APPLY_HARDENING="${APPLY_HARDENING:-0}"
OUTDIR="${OUTDIR:-${SCRIPT_DIR}/images}"

ALL_DISTROS=("al2023" "fedora" "rocky8" "rocky9" "ubuntu22" "ubuntu24")

if [ -z "${TARGET}" ]; then
  echo "======================================================================"
  echo "  KISA Linux Hardening - Vagrant Box Builder"
  echo "======================================================================"
  echo "사용법: bash vagrant/build_image.sh [DISTRO|all]"
  echo
  echo "지원 배포판:"
  echo "  - al2023     (Amazon Linux 2023)"
  echo "  - fedora     (Fedora 41)"
  echo "  - rocky8     (Rocky Linux 8)"
  echo "  - rocky9     (Rocky Linux 9)"
  echo "  - ubuntu22   (Ubuntu 22.04 LTS)"
  echo "  - ubuntu24   (Ubuntu 24.04 LTS)"
  echo "  - all        (모든 배포판 순차 빌드)"
  echo
  echo "옵션 환경변수:"
  echo "  APPLY_HARDENING=1   # 하드닝 적용 후 골든 이미지 생성"
  echo "  OUTDIR=path         # 생성 파일 저장 디렉토리 (기본: vagrant/images)"
  exit 1
fi

mkdir -p "${OUTDIR}"
cd "${SCRIPT_DIR}"

package_one_distro() {
  local distro="$1"
  local timestamp
  timestamp="$(date +%Y%m%d_%H%M%S)"

  local label="base"
  if [ "${APPLY_HARDENING}" = "1" ] || [ "${APPLY_HARDENING}" = "true" ]; then
    label="hardened"
  fi

  local out_file="${OUTDIR}/kisa-${distro}-${label}-${timestamp}.box"
  local latest_symlink="${OUTDIR}/kisa-${distro}-${label}-latest.box"

  echo
  echo "======================================================================"
  echo ">>> [${distro}] 이미지 빌드 시작 (타입: ${label})"
  echo "======================================================================"

  # 1. VM 기동 여부 확인 및 기동
  local state
  state="$(vagrant status "${distro}" --machine-readable 2>/dev/null | grep ',state,' | cut -d',' -f4 || echo "unknown")"
  if [ "${state}" != "running" ]; then
    echo ">>> VM '${distro}' 기동 중..."
    vagrant up "${distro}"
  else
    echo ">>> VM '${distro}' 실행 상태 확인됨."
  fi

  # 2. 하드닝 적용 (옵션 활성화 시)
  if [ "${APPLY_HARDENING}" = "1" ] || [ "${APPLY_HARDENING}" = "true" ]; then
    echo
    echo ">>> KISA 하드닝 플레이북 적용 중 (distro: ${distro})..."
    cd "${ROOT_DIR}"
    ansible-playbook -i inventory/vagrant.ini plays/site.yml -e "distro_select=${distro}" --diff
    cd "${SCRIPT_DIR}"
  fi

  # 3. 게스트 OS 내부 클린업 (로그, 임시 파일, 셸 히스토리 등 정리)
  echo
  echo ">>> 게스트 OS 임시 파일 정리 및 클린업..."
  vagrant ssh "${distro}" -c "
    sudo rm -rf /tmp/* /var/tmp/*
    sudo journalctl --vacuum-time=1s 2>/dev/null || true
    sudo rm -f /var/log/*.gz /var/log/*.1 /var/log/*.[0-9] 2>/dev/null || true
    history -c 2>/dev/null || true
    sync
  " || true

  # 4. VM 정상 종료 (VirtualBox/Libvirt 패키징 전 권장)
  echo
  echo ">>> 패키징을 위해 VM 안전 종료 (vagrant halt ${distro})..."
  vagrant halt "${distro}"

  # 5. Vagrant Package 실행
  echo
  echo ">>> Vagrant 박스 패키징 진행: ${out_file}"
  vagrant package "${distro}" --output "${out_file}"

  # 6. 최신 링크 갱신
  ln -sf "$(basename "${out_file}")" "${latest_symlink}"

  local filesize
  filesize="$(du -h "${out_file}" | cut -f1)"

  echo
  echo "----------------------------------------------------------------------"
  echo " [성공] ${distro} 박스 생성 완료!"
  echo "  * 파일: ${out_file} (${filesize})"
  echo "  * 최신 링크: ${latest_symlink}"
  echo "----------------------------------------------------------------------"
  echo " [Box 등록 및 사용법]"
  echo "  1) 박스 로컬 등록:"
  echo "     vagrant box add kisa/${distro}-${label} ${out_file}"
  echo "  2) 새 프로젝트에서 사용:"
  echo "     vagrant init kisa/${distro}-${label}"
  echo "----------------------------------------------------------------------"
}

if [ "${TARGET}" = "all" ]; then
  for d in "${ALL_DISTROS[@]}"; do
    package_one_distro "${d}"
  done
else
  # 유효한 배포판인지 확인
  valid=0
  for d in "${ALL_DISTROS[@]}"; do
    if [ "${d}" = "${TARGET}" ]; then
      valid=1
      break
    fi
  done

  if [ "${valid}" -eq 0 ]; then
    echo "[ERROR] 알 수 없는 배포판: '${TARGET}'"
    echo "        선택 가능: ${ALL_DISTROS[*]} 또는 all"
    exit 1
  fi

  package_one_distro "${TARGET}"
fi

echo
echo "======================================================================"
echo " 모든 지정된 이미지 생성이 완료되었습니다. (저장소: ${OUTDIR})"
echo "======================================================================"
