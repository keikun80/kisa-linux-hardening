#!/usr/bin/env bash
# ==============================================================================
# Admin 노드로 프로젝트 코드 및 SSH 키 동기화 스크립트
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${SCRIPT_DIR}"

ADMIN_IP="$(terraform output -json admin_node 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin).get('public_ip', ''))")"
SSH_USER="$(terraform output -json admin_node 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin).get('ssh_user', 'ubuntu'))")"

if [ -z "${ADMIN_IP}" ]; then
  echo "[ERROR] Admin 노드 IP를 가져올 수 없습니다. 먼저 'bash terraform/deploy.sh'를 실행해주세요."
  exit 1
fi

SSH_KEY="${HOME}/.ssh/id_ed25519"
if [ ! -f "${SSH_KEY}" ]; then
  SSH_KEY="${HOME}/.ssh/id_rsa"
fi

echo "======================================================================"
echo " Admin 노드 (${ADMIN_IP})로 코드 동기화 시작"
echo "======================================================================"

# 1. Admin 노드의 SSH 포트 준비 대기
echo ">>> [1/3] Admin 노드 SSH 연결 대기 중..."
until ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${SSH_USER}@${ADMIN_IP}" "echo 'SSH Connected'" >/dev/null 2>&1; do
  sleep 3
done

# 2. 타깃 노드 접속용 개인키를 Admin 노드 ~/.ssh 에 복사
echo ">>> [2/3] Admin 노드에 SSH 개인키 배포..."
scp -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${SSH_KEY}" "${SSH_USER}@${ADMIN_IP}:~/.ssh/id_ed25519"
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${SSH_USER}@${ADMIN_IP}" "chmod 600 ~/.ssh/id_ed25519"

# 3. 프로젝트 코드 rsync 동기화
echo ">>> [3/3] 프로젝트 코드 동기화..."
rsync -avz --exclude='.git' --exclude='.vagrant' --exclude='reports' --exclude='terraform/.terraform' \
  -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
  "${ROOT_DIR}/" "${SSH_USER}@${ADMIN_IP}:~/kisa-linux-hardening/"

# 4. Admin 노드 내부 인벤토리 배치
scp -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${SCRIPT_DIR}/inventory_admin.ini" "${SSH_USER}@${ADMIN_IP}:~/kisa-linux-hardening/inventory/ec2.ini"

echo
echo "======================================================================"
echo " [완료] 코드 동기화가 완료되었습니다."
echo "----------------------------------------------------------------------"
echo " Admin 노드 접속:"
echo "   ssh -i ${SSH_KEY} ${SSH_USER}@${ADMIN_IP}"
echo
echo " Admin 노드 내부에서 감사 실행:"
echo "   cd ~/kisa-linux-hardening"
echo "   bash scripts/audit.sh"
echo "======================================================================"
