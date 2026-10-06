#!/usr/bin/env bash
# ==============================================================================
# Vagrant 기반 AL2023 / Fedora / Ubuntu 22 / 24 KISA 하드닝 감사 및 테스트 래퍼
# ==============================================================================
# 사용법:
#   bash scripts/vagrant_test.sh                  # 모든 VM 기동 및 감사 수행
#   DISTRO=al2023 bash scripts/vagrant_test.sh    # AL2023만 기동 및 감사
#   DISTRO=fedora bash scripts/vagrant_test.sh    # Fedora만 기동 및 감사
#   DISTRO=ubuntu22 bash scripts/vagrant_test.sh   # Ubuntu 22만 기동 및 감사
#   DISTRO=ubuntu24 bash scripts/vagrant_test.sh   # Ubuntu 24만 기동 및 감사
#   ACTION=apply bash scripts/vagrant_test.sh      # 실제 적용 (기본: check/audit)
# ==============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

DISTRO="${DISTRO:-all}"
ACTION="${ACTION:-audit}"
INV="inventory/vagrant.ini"

command -v vagrant >/dev/null 2>&1 || {
  echo "[ERROR] vagrant 명령어가 설치되어 있지 않습니다. (예: brew install hashicorp/tap/hashicorp-vagrant)"
  exit 1
}

echo "=== [1/3] Vagrant VM 기동 ==="
case "${DISTRO}" in
  al2023)
    vagrant up al2023
    ;;
  fedora)
    vagrant up fedora
    ;;
  ubuntu22)
    vagrant up ubuntu22
    ;;
  ubuntu24)
    vagrant up ubuntu24
    ;;
  all)
    vagrant up
    ;;
  *)
    echo "알 수 없는 DISTRO: ${DISTRO} (선택: al2023, fedora, ubuntu22, ubuntu24, all)"
    exit 1
    ;;
esac

echo
echo "=== [2/3] Vagrant SSH 연결 대기 및 상태 확인 ==="
vagrant status

echo
echo "=== [3/3] KISA 하드닝 ${ACTION} 실행 ==="
if [ "${ACTION}" = "audit" ]; then
  if [ "${DISTRO}" = "all" ]; then
    INV="${INV}" bash scripts/audit.sh
  else
    INV="${INV}" DISTRO="${DISTRO}" bash scripts/audit.sh
  fi
elif [ "${ACTION}" = "apply" ]; then
  if [ "${DISTRO}" = "all" ]; then
    ansible-playbook -i "${INV}" plays/site.yml --diff
  else
    ansible-playbook -i "${INV}" plays/site.yml -e "distro_select=${DISTRO}" --diff
  fi
else
  echo "알 수 없는 ACTION: ${ACTION} (선택: audit, apply)"
  exit 1
fi

echo
echo "=== 테스트 완료 ==="
echo "VM 중지: vagrant halt [al2023|fedora|ubuntu22|ubuntu24]"
echo "VM 삭제: vagrant destroy -f [al2023|fedora|ubuntu22|ubuntu24]"
