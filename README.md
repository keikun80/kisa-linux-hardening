# qwen_ansible — KISA Linux 취약점 감사·강화 플레이북

주요정보통신기반시설「기술적 취약점 분석·평가 상세가이드」(Linux, U-01~U-67)를
Ansible 역할 하나로 자동화한 것이다. 67개 점검항목을 계정(accounts, U-01~13) ·
파일(files, U-14~33) · 서비스(services, U-34~62) · 생명주기(lifecycle, U-63~67)
네 묶음으로 나누어 제공한다.

## 구성

| 경로 | 역할 |
|---|---|
| `plays/site.yml` | 유일한 진입점 플레이 — 대상은 `distro_select`(기본 `all`, `-e distro_select=al2023` 등). `serial: 1`, `become: sudo` |
| `roles/kisa_linux_harden/` | 역할 — `tasks/`(번호별 점검 태스크) `defaults/` `handlers/` |
| `group_vars/<distro>/` | al2023 · fedora · ubuntu 특화 프로파일 (패키지명, PAM 스위치, chrony 유닛 등) |
| `inventory/` | 정적 인벤토리 (`ec2.ini`는 예시 상태 — 실호스트 입력 필요) |
| `scripts/audit.sh` | 일일 감사 드라이버: `--check --diff` 강제 실행 → `reports/<시간>/` 생성 |
| `callbacks/results_json.py` | 표준 출력의 색이 묻지 않도록 이벤트를 NDJSON으로 **stderr** 에 흘림 |
| `scripts/report.py` | NDJSON 수집 → `SUMMARY.md`(호스트×U-ID 매트릭스) + `detail.csv` |
| `scripts/detect_contamination.py` | 문서·코드의 외부 문자(CJK 계열) 침투 회귀 검사 |
| `_selftest/local.ini` | 로컬(smoke) 실험용 인벤토리 — localhost 를 ubuntu 그룹으로 등록 |
| `reports/` | `audit.sh` 감사 산출물 (실행마다 생성: `raw.log`, `events.ndjson`, `SUMMARY.md`, `detail.csv`) |
| `_source_ref/` | 벤더참고: 기존 셸 스크립트 감사기(MIT)와 수동 체크 가이드 (읽기 전용 베이스라인) |

## 빠른 시작

root 권이 필요 (플레이에 `become: sudo` 포함되어 있음).

```bash
# 읽기 전용 감사 (권장 시작선) — reports/<ts>/ 에 결과물 생성
bash scripts/audit.sh                          # 전체
bash scripts/audit.sh -t u-65                  # 단일 항목
bash scripts/audit.sh -t cat.accounts          # 카테고리 단위
INV=inventory/myfleet.ini bash scripts/audit.sh

# 배포그룹 선택 (al2023 / fedora / ubuntu) — group_vars 프로파일 자동 추종
DISTRO=al2023 bash scripts/audit.sh                                  # 래퍼: DISTRO 환경변수
ansible-playbook -i inventory/ec2.ini plays/site.yml -e distro_select=ubuntu --check
                                                                     # 직접: distro_select 변수
# 타깃 검증만: ... --list-hosts (실행 없음)

# 실제 적용 (상태 변경) — 반드시 --diff 로 변경량을 먼저 본다
ansible-playbook -i inventory/ec2.ini plays/site.yml --diff

# 로컬 스모크 테스트 (대상 머신 = 로컬, 체크모드)
ansible-playbook -i _selftest/local.ini plays/site.yml --check
```

태그 체계: 항목별 `u-01`~`u-67`, 카테고리별 `cat.accounts`·`cat.files`·`cat.services`·`cat.lifecycle`.

## 보고서 읽기

`SUMMARY.md` 는 호스트 × U-ID 매트릭스로 등급 기호가 붙는다.

- `✗` 실패(FAILED) · `▲` 변경(CHANGED) · `◇` 조언·수동확인(INFO) · `·` 정상/무변경
- 태스크명에 `[U-XX:M]` 접두의 항목은 “기계로는 판단 불가”이므로 자동으로 INFO 로 분류된다.
- `detail.csv` 는 동일 데이터의 엑셀용 평평한 형태로 제공된다.

## 고위험 토글

아래 스위치는 `defaults/main.yml` 에 **기본 OFF** 로 선언되어 있고, `true` 로 켜면
`00_prep` 시작 시점에 “HIGH-RISK TOGGLE ENABLED” 알림이 몰려 나간다. 켜기 전에
`vu_backups_root`(기본 `/opt/backups/kisa_hardening`) 근처 백업을 습관을 들인다.

| 토글 | 효과 |
|---|---|
| `vu_pam_strict_stack` | U-02/U-03 PAM 스택(faillock/pwquality) 직접 주입 — distro 프로필이 이미 덮어씀 |
| `vu_manage_host_firewall` | U-28 firewalld/ufw 활성화 (`vu_firewall_allow_sources` 비어 있으면 경고 후 스킵) |
| `vu_legacy_service_cleanup` | U-34~U-54 계열 불필요 서비스 **패키지 제거** (OFF 시 중지+mask 까지만) |
| `vu_mask_rpcbind` | U-42 rpcbind mask — 외부 NFS 마운트 사용자는 절대 OFF 로 둘 것 |
| `vu_lock_extra_uid0` | U-05 root 외 UID-0 계정 자동 격리(잠금+셸 제거) |
| `vu_apply_dup_uid` | U-10 중복 UID 재할당 (`vu_dup_uid_newvals` 매핑 필수) |
| `vu_strip_world_writable` | U-25 세계쓰기 비트 자동 제거 |
| `vu_del_ftp_pub_dir` | U-35 `/var/ftp/pub` 물리 삭제 |
| `vu_nfs_manage_exports` | U-40 `/etc/exports` 재생성 |

상대적으로 가벼운 기본-ON 사항: `vu_quarantine_plain_hashes`(U-04, `/etc/passwd` 내
해시 격리), `vu_disable_plaintext_ftp`(U-54), `vu_autopatch_security`(U-64 정기 보안
패치 — dnf-automatic / unattended-upgrades), `vu_snmp_community_probe`(U-60 보고 프로브).

## 항목의 문법

- `[U-XX] …` — 자동 집행 또는 측정 태스크
- `[U-XX:M] …` — 조언·수동 확인 (리포트에서 INFO 로 승격)
- `:scan`·`:probe` 등 장식 접미는 실행 단계 구분용이며, 리포트 매핑에는 `[U-XX]`/`:M`
  접두만 의미를 가진다 (접두 문법이므로 임의로 바꾸지 말 것).

## 보조 스크립트

- `scripts/audit.sh` — `ANSIBLE_STDOUT_CALLBACK` 은 `callbacks/` 디렉터리 자동탐지에 의존.
  환경변수 `INV` 로 인벤토리, `DISTRO`(al2023/fedora/ubuntu) 로 배포그룹을 선택하고,
  나머지 인수는 `ansible-playbook` 에 통째로 넘김. `DISTRO` 값이 인벤토리의 그룹으로
  존재하지 않으면 실행 전에 거절(exit 2).
- `scripts/detect_contamination.py` — 한자/카타카나 계열 코드의 침입을 잡아내는 회귀
  검사. 주기적 실행 권장 (`TOTAL_LINES: 0` 이 정상).
- `scripts/fix_known_lines.py` — 과거 문자열 오염 사건 당시의 1회성 라인 패처
  (역사적 산물로 남겨둠, 일반적으로 재실행할 일이 없음).
