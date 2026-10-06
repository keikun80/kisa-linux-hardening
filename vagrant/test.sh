#!/usr/bin/env bash
# ==============================================================================
# Vagrant 기반 AL2023 / Fedora / Rocky 8/9/10 / Ubuntu 22/24 KISA 하드닝 감사 및 테스트
# ==============================================================================
# 사용법:
#   bash vagrant/test.sh                  # 모든 VM 기동 및 감사(audit) 수행
#   bash vagrant/test.sh al2023           # AL2023만 기동 및 감사
#   bash vagrant/test.sh fedora           # Fedora만 기동 및 감사
#   bash vagrant/test.sh rocky8           # Rocky 8만 기동 및 감사
#   bash vagrant/test.sh rocky9           # Rocky 9만 기동 및 감사
#   bash vagrant/test.sh rocky10          # Rocky 10만 기동 및 감사
#   bash vagrant/test.sh ubuntu22         # Ubuntu 22만 기동 및 감사
#   bash vagrant/test.sh ubuntu24         # Ubuntu 24만 기동 및 감사
#   ACTION=apply bash vagrant/test.sh     # 실제 적용 (기본: check/audit)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DISTRO="${1:-${DISTRO:-all}}"
ACTION="${ACTION:-audit}"
INV="${ROOT_DIR}/inventory/vagrant.ini"

command -v vagrant >/dev/null 2>&1 || {
  echo "[ERROR] vagrant 명령어가 설치되어 있지 않습니다. (예: brew install hashicorp/tap/hashicorp-vagrant)"
  exit 1
}

cd "${SCRIPT_DIR}"

echo "=== [1/3] Vagrant VM 기동 ==="
case "${DISTRO}" in
  al2023)
    vagrant up al2023
    ;;
  fedora)
    vagrant up fedora
    ;;
  rocky8)
    vagrant up rocky8
    ;;
  rocky9)
    vagrant up rocky9
    ;;
  rocky10)
    vagrant up rocky10
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
    echo "알 수 없는 DISTRO: ${DISTRO} (선택: al2023, fedora, rocky8, rocky9, rocky10, ubuntu22, ubuntu24, all)"
    exit 1
    ;;
esac

echo
echo "=== [2/3] Vagrant SSH 연결 대기 및 상태 확인 ==="
vagrant status

echo
echo "=== [3/3] KISA 하드닝 ${ACTION} 실행 ==="
cd "${ROOT_DIR}"
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
echo "VM 중지: (cd vagrant && vagrant halt [distro])"
echo "VM 삭제: (cd vagrant && vagrant destroy -f [distro])"
