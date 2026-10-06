#!/usr/bin/env bash
# ==============================================================================
# AWS KISA 하드닝 테스트 인프라 배포 스크립트 (Terraform Apply)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${SCRIPT_DIR}"

command -v terraform >/dev/null 2>&1 || {
  echo "[ERROR] terraform 명령어를 찾을 수 없습니다. (https://developer.hashicorp.com/terraform/install)"
  exit 1
}

echo "=== [1/3] Terraform 초기화 (terraform init) ==="
terraform init

echo
echo "=== [2/3] Terraform 인프라 배포 (terraform apply) ==="
terraform apply -auto-approve "$@"

echo
echo "=== [3/3] 배포 완료 및 인벤토리 확인 ==="
echo "생성된 인벤토리:"
echo "  - 로컬 직접 접속용:  inventory/aws_ec2.ini"
echo "  - Admin 노드 내부용: terraform/inventory_admin.ini"
echo
terraform output -raw quick_start_instructions 2>/dev/null || terraform output
