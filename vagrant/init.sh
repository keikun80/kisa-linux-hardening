#!/usr/bin/env bash
# ==============================================================================
# Vagrant 테스트 환경 초기화 스크립트
# ==============================================================================
# 설명:
#   지정된 Vagrant VM(또는 전체)을 삭제(destroy)하고 새로 기동(up)하여
#   초기 깨끗한 상태로 재구성합니다.
#
# 사용법:
#   bash vagrant/init.sh                   # 전체 VM 초기화 및 기동
#   bash vagrant/init.sh al2023            # al2023만 초기화
#   bash vagrant/init.sh ubuntu22          # ubuntu22만 초기화
#   DISTRO=rocky9 bash vagrant/init.sh     # rocky9만 초기화
#   DISTRO=rocky10 bash vagrant/init.sh    # rocky10만 초기화
#
# 지원 배포판: al2023, fedora, rocky8, rocky9, rocky10, ubuntu22, ubuntu24, all
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DISTRO="${1:-${DISTRO:-all}}"

echo "======================================================================"
echo "  KISA Linux Hardening - Vagrant Environment Initializer"
echo "======================================================================"
echo "  * 타깃 VM    : ${DISTRO}"
echo "  * 작업 디렉터리 : ${SCRIPT_DIR}"
echo "======================================================================"

# 1. Vagrant 명령어 확인
command -v vagrant >/dev/null 2>&1 || {
  echo "[ERROR] 'vagrant' 명령어를 찾을 수 없습니다."
  echo "        Vagrant를 먼저 설치해주세요 (예: https://developer.hashicorp.com/vagrant/install)"
  exit 1
}

# 2. 호스트 SSH 키 확인 안내
if [ ! -f "${HOME}/.ssh/id_ed25519.pub" ] && [ ! -f "${HOME}/.ssh/id_rsa.pub" ]; then
  echo "[INFO] 호스트 머신에 SSH 공개키(~/.ssh/id_ed25519.pub 또는 id_rsa.pub)가 없습니다."
  echo "       자동 로그인을 위해 키 생성을 권장합니다: ssh-keygen -t ed25519"
fi

cd "${SCRIPT_DIR}"

# 3. 기존 VM 삭제 (destroy)
echo
echo ">>> [1/3] 기존 VM 삭제 (vagrant destroy -f)"
if [ "${DISTRO}" = "all" ]; then
  vagrant destroy -f
else
  vagrant destroy -f "${DISTRO}"
fi

# 4. VM 새로 기동 (up)
echo
echo ">>> [2/3] VM 새로 기동 (vagrant up)"
if [ "${DISTRO}" = "all" ]; then
  vagrant up
else
  vagrant up "${DISTRO}"
fi

# 5. 상태 확인
echo
echo ">>> [3/3] VM 상태 및 SSH 연결 확인"
vagrant status

echo
echo "======================================================================"
echo " [완료] Vagrant VM 초기화가 성공적으로 끝났습니다."
echo "----------------------------------------------------------------------"
echo "  - 테스트 실행:  bash vagrant/test.sh [DISTRO]"
echo "  - 이미지 빌드:  bash vagrant/build_image.sh [DISTRO]"
echo "  - SSH 접속:    vagrant ssh [DISTRO]"
echo "======================================================================"
