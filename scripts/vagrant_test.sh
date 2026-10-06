#!/usr/bin/env bash
# ==============================================================================
# Vagrant 기반 AL2023 / Fedora / Rocky 8/9/10 / Ubuntu 22/24 KISA 하드닝 감사 및 테스트 래퍼
# ==============================================================================
# (vagrant/test.sh 로 위임 실행)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

exec bash "${ROOT_DIR}/vagrant/test.sh" "$@"
