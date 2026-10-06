#!/usr/bin/env bash
# ==============================================================================
# AWS KISA 하드닝 테스트 인프라 삭제 스크립트 (Terraform Destroy)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${SCRIPT_DIR}"

command -v terraform >/dev/null 2>&1 || {
  echo "[ERROR] terraform 명령어를 찾을 수 없습니다."
  exit 1
}

echo "=== AWS KISA 하드닝 테스트 인프라 완전 삭제 (terraform destroy) ==="
terraform destroy -auto-approve "$@"

# 자동 생성된 인벤토리 정리
rm -f "${ROOT_DIR}/inventory/aws_ec2.ini" "${SCRIPT_DIR}/inventory_admin.ini"

echo
echo "[완료] 모든 AWS 테스트 리소스가 성공적으로 정리되었습니다."
