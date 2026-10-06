#!/usr/bin/env bash
# ==============================================================================
# AWS KISA 하드닝 테스트 & 감사 실행 스크립트
# ==============================================================================
# 사용법:
#   bash terraform/test.sh                     # 로컬에서 전체 AWS 노드 전수 감사
#   bash terraform/test.sh al2023              # al2023만 감사
#   ACTION=apply bash terraform/test.sh rocky9 # rocky9에 실제 하드닝 적용
#   MODE=remote bash terraform/test.sh         # Admin 노드 내부에서 원격으로 실행
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DISTRO="${1:-${DISTRO:-all}}"
ACTION="${ACTION:-audit}"
MODE="${MODE:-local}" # local 또는 remote (Admin 노드 내부 실행)

cd "${ROOT_DIR}"

if [ "${MODE}" = "remote" ]; then
  echo ">>> Admin 노드를 통한 원격 KISA 하드닝 ${ACTION} 실행..."
  bash "${SCRIPT_DIR}/sync_to_admin.sh"

  ADMIN_IP="$(cd "${SCRIPT_DIR}" && terraform output -json admin_node 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin).get('public_ip', ''))")"
  SSH_KEY="${HOME}/.ssh/id_ed25519"
  [ ! -f "${SSH_KEY}" ] && SSH_KEY="${HOME}/.ssh/id_rsa"

  if [ "${DISTRO}" = "all" ]; then
    ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "ubuntu@${ADMIN_IP}" \
      "cd ~/kisa-linux-hardening && if [ '${ACTION}' = 'apply' ]; then ansible-playbook -i inventory/ec2.ini plays/site.yml --diff; else bash scripts/audit.sh; fi"
  else
    ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "ubuntu@${ADMIN_IP}" \
      "cd ~/kisa-linux-hardening && if [ '${ACTION}' = 'apply' ]; then ansible-playbook -i inventory/ec2.ini plays/site.yml -e distro_select=${DISTRO} --diff; else DISTRO=${DISTRO} bash scripts/audit.sh; fi"
  fi
else
  INV="inventory/aws_ec2.ini"
  if [ ! -f "${INV}" ]; then
    echo "[ERROR] ${INV} 파일이 존재하지 않습니다. 먼저 'bash terraform/deploy.sh'를 실행해주세요."
    exit 1
  fi

  echo ">>> 로컬 호스트에서 AWS 인스턴스 대상 KISA ${ACTION} 직접 실행 (인벤토리: ${INV})..."
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
fi
