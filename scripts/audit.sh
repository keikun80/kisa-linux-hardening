#!/usr/bin/env bash
# ==============================================================================
# KISA 취약점 감사 래퍼 — ansible-playbook --check (DRY-RUN) 의 결과를
# '호스트 x U-ID' 매트릭스로 묶어 리포트(reports/) 로 보관한다.
#
#   ./audit.sh                                    # 전체 인벤토리
#   DISTRO=al2023 ./audit.sh                      # 배포그룹 선택 (al2023/fedora/ubuntu)
#   INV=inventory/ec2.ini ./audit.sh -t u-65     # 특정 태그만
#   EXTRA="--diff" ./audit.sh
#
# 판정:
#   양호(OK)        : 관련 태스크가 전부 변경 없음
#   개선필요(CHG)   : 변경 예정 항목 있음 (= 점검 스크립트상 '취약' 예상)
#   진단(INFO)      : [U-XX:M] 진단 항목(사람 확인 필요)
#   오류(ERROR)     : 실행 중 실패 (setup/권한 부족 등)
# ==============================================================================
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

INV="${INV:-inventory/ec2.ini}"
TS="$(date +%Y%m%d_%H%M%S)"
DIR="reports/${TS}_$$"
RAW="${DIR}/raw.log"
NDJSON="${DIR}/events.ndjson"
mkdir -p "${DIR}"

ARGS=("${@}")

# 배포그룹 선택: DISTRO=al2023 | fedora | ubuntu (미설정 = 전체 인벤토리)
DISTRO="${DISTRO:-}"
if [ -n "${DISTRO}" ]; then
  case "${DISTRO}" in
    al2023|fedora|ubuntu) ;;
    *) echo "[audit] DISTRO='${DISTRO}' 인식을 못 했습니다 — 선택: al2023, fedora, ubuntu (미설정은 전체)"; exit 2;;
  esac
  if ! grep -qE "^[[:space:]]*\[${DISTRO}\]" "${INV}" 2>/dev/null; then
    echo "[audit] 인벤토리 ${INV} 에 '${DISTRO}' 그룹이 없습니다"
    exit 2
  fi
  ARGS+=(-e "distro_select=${DISTRO}")
fi

# 기본 --check: dry-run 강제 (이미 붙었다면 중복 무시)
HAS_CHECK=0
for a in "${ARGS[@]}"; do [ "$a" = "--check" ] && HAS_CHECK=1; done
[ "${HAS_CHECK}" = "1" ] || ARGS+=(--check)

echo "[audit] 인벤토리=${INV}${DISTRO:+ (배포그룹=${DISTRO})}"
echo "[audit] 출력 디렉토리=${DIR}"
echo "[audit] 시작..."

# colormixin 없이 표준 출력을 로깅 + callbacks 가 뿌린 NDJSON(stderr) 를 분리
ANSIBLE_LOCALHOST_WARNING=False \
ANSIBLE_DEPRECATION_WARNINGS=False \
ANSIBLE_STDOUT_CALLBACK=default \
ansible-playbook -i "${INV}" plays/site.yml --diff \
  "${ARGS[@]}" \
  1>${RAW} 2> >(tee /dev/stderr | grep '^{.*}' > "${NDJSON}" 2>/dev/null &) || \
  { echo "[audit] 실행 코드 $? (일부 호스트 실패 가능)"; }

python3 scripts/report.py --ndjson "${NDJSON}" --outdir "${DIR}" --title "KISA Linux 취약점 감사 ${TS}"
CODE=$?

echo
echo "================================================================"
if [ ${CODE} -eq 0 ]; then
    echo " 리포트: ${DIR}/SUMMARY.md   (CSV: ${DIR}/detail.csv)"
else
    echo " 리포트 생성 중 문제 발생 (${DIR}/raw.log 을 확인)"
fi
echo "================================================================"
exit ${CODE}
