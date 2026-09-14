# qwen_ansible — KISA Linux 취약점 감사·강화 플레이북

> **KISA(한국인터넷보안아카데미) 주요정보통신기반시설 기술적 취약점 분석·평가 상세가이드**에 맞춰 Linux 서버 67개 점검항목(U-01~U-67)을 Ansible로 자동화합니다.
>
> 읽기 전용 감사에서 실제 강화 적용까지 — 한 playbook으로 끝냅니다.

## 사전 요구사항

| 항목 | 필요조건 |
|------|----------|
| Ansible | 2.9 이상 (컨트롤 노드에 설치) |
| Python 3 | 컨트롤 노드 + 타깃 호스트 |
| sudo/root | 타깃 호스트에서 root 권한 elevate 가능 |
| SSH | 컨트롤 노드 → 타깃 호스트 연결 가능 |
| 인벤토리 | `inventory/ec2.ini`에 실제 호스트 주소 입력 |

## 지원 배포판

| 배포판 | 그룹명 | 특화 프로필 |
|--------|--------|-------------|
| Amazon Linux 2023 | `al2023` | dnf-automatic, chronyd, PAM 스택 자동구성 |
| Fedora | `fedora` | dnf-automatic, chronyd, PAM 스택 자동구성 |
| Ubuntu | `ubuntu` | unattended-upgrades, chrony, PAM 스택 수동모드 |

배포판별 패키지명, PAM 설정, 시스템 서비스 등의 차이는 `group_vars/<그룹>/`에서 자동 적용됩니다.

---

## 빠른 시작

### ① 읽기 전용 감사 (권장 시작)

시스템에 아무 변경 없이 "적합 여부만 점검"합니다. 결과는 `reports/<시간>/`에 저장됩니다.

```bash
# 전체 인벤토리 전수 감사
bash scripts/audit.sh

# 특정 배포그룹만
DISTRO=ubuntu bash scripts/audit.sh

# 단일 점검 항목만
bash scripts/audit.sh -t u-65

# 카테고리 단위 (계정/파일/서비스/생명주기)
bash scripts/audit.sh -t cat.accounts
```

### ② 실제 적용 (상태 변경)

감사 결과를 확인한 후, 실제 서버 설정을 변경합니다. **반드시 `--diff`로 변경량을 먼저 확인하세요.**

```bash
# 변경량만 확인 (미리보기)
ansible-playbook -i inventory/ec2.ini plays/site.yml --diff

# 변경 적용
ansible-playbook -i inventory/ec2.ini plays/site.yml

# 특정 배포그룹 대상
ansible-playbook -i inventory/ec2.ini plays/site.yml -e distro_select=al2023 --diff
```

### ③ 로컬 테스트

실제 타깃 없이 로컬에서 동작을 확인합니다.

```bash
ansible-playbook -i _selftest/local.ini plays/site.yml --check
```

---

## 프로젝트 구조

| 경로 | 역할 |
|------|------|
| `plays/site.yml` | 진입점 — `serial: 1`(순차실행), `become: sudo` |
| `roles/kisa_linux_harden/` | 핵심 역할: `tasks/`(번호별 태스크), `defaults/`(설정), `handlers/` |
| `group_vars/<그룹>/` | al2023 · fedora · ubuntu별 특화 프로파일 |
| `inventory/ec2.ini` | 정적 인벤토리 (실제 호스트 주소 입력 필요) |
| `scripts/audit.sh` | 감사 래퍼: `--check --diff` 강제 → `reports/<시간>/` 생성 |
| `scripts/report.py` | NDJSON → `SUMMARY.md`(매트릭스) + `detail.csv` |
| `scripts/detect_contamination.py` | 문서·코드 외부 문자(CJK) 침투 회귀검사 |
| `callbacks/results_json.py` | NDJSON 이벤트 출력 콜백 (stderr) |
| `_selftest/local.ini` | 로컬 스모크테스트 인벤토리 |
| `reports/` | 감사 산출물 (실행당 1개 디렉토리) |
| `_source_ref/` | 기존 셸스크립트 감사기, 수동체크 가이드 (읽기 전용) |

---

## 도구

| 도구 | 목적 | 실행 |
|------|------|------|
| `scripts/audit.sh` | 읽기 전용 감사 + 리포트 자동생성 | `bash scripts/audit.sh` |
| `scripts/report.py` | NDJSON 이벤트 → SUMMARY.md + CSV 변환 | `audit.sh`가 내부에서 자동 호출 |
| `scripts/detect_contamination.py` | 프로젝트 내 외부 문자(CJK) 침투 검사 | `python3 scripts/detect_contamination.py` |
| `scripts/fix_known_lines.py` | 과거 문자 오염 사건 1회성 패처 (역사적 산물) | 일반적으로 재실행 불필요 |

### 감사 래퍼 (`audit.sh`) 환경변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `INV` | 인벤토리 파일 경로 (기본: `inventory/ec2.ini`) | `INV=inventory/myfleet.ini` |
| `DISTRO` | 배포그룹 선택 (al2023 / fedora / ubuntu) | `DISTRO=al2023` |

---

## 보고서 읽기

`reports/<시간>/SUMMARY.md`는 **호스트 × U-ID 매트릭스** 형태로 결과를 제공합니다.

### 판정 기호

| 기호 | 의미 | 설명 |
|------|------|------|
| ✗ | **FAIL** (실패) | 현재 설정이 가이드 기준에 미달함 |
| ▲ | **CHANGED** (변경예정) | 적용 시 설정이 변경됨 = 개선 필요 |
| ◇ | **INFO** (조언·수동확인) | `[U-XX:M]` 항목 — 기계 판단 불가, 사람이 확인해야 함 |
| · | **OK** (정상·무변경) | 기준 충족, 조치 불필요 |

### 파일

- **`SUMMARY.md`** — 호스트 × U-ID 매트릭스 (가독성 중심)
- **`detail.csv`** — 동일 데이터를 엑셀에서 열람 가능한 형식

---

## 태그 시스템

각 점검 항목은 개별 태그와 카테고리 태그를 동시에 가집니다.

| 태그 | 설명 | 예시 |
|------|------|------|
| `u-01` ~ `u-67` | 개별 점검 항목 | `-t u-65` |
| `cat.accounts` | 계정 관리 (U-01~13) | `-t cat.accounts` |
| `cat.files` | 파일·디렉터리 관리 (U-14~33) | `-t cat.files` |
| `cat.services` | 서비스 관리 (U-34~62) | `-t cat.services` |
| `cat.lifecycle` | 생명주기 관리 (U-63~67) | `-t cat.lifecycle` |

### 태스트 이름 접두사

- `[U-XX]` — 자동 집행 또는 측정 가능한 태스크
- `[U-XX:M]` — **수동 확인 필요**. 기계로는 판단할 수 없어 리포트에서 INFO로 분류됩니다

---

## 고위험 토글

다음 스위치는 `roles/kisa_linux_harden/defaults/main.yml`에서 **기본 OFF**로 선언되어 있습니다.
`true`로 활성화하면 `00_prep` 단계에서 "HIGH-RISK TOGGLE ENABLED" 알림이 출력됩니다.

활성화 전에 **반드시** `vu_backups_root`(기본 `/opt/backups/kisa_hardening`)에 백업을 확인하세요.

### 기본 OFF (고위험)

| 토글 | 영향 | 설명 | 활성화 조건 |
|------|------|------|-------------|
| `vu_pam_strict_stack` | 🔴 PAM 재구성 | U-02/U-03 PAM 스택(faillock/pwquality) 직접 주입 | distro 프로필이 처리하지 않는 경우만 |
| `vu_manage_host_firewall` | 🔴 네트워크 차단 | U-28 firewalld/ufw 활성화 | `vu_firewall_allow_sources`에 허용 출처 명시 후 |
| `vu_legacy_service_cleanup` | 🟡 패키지 제거 | U-34~U-54 불필요 서비스 패키지 삭제 (OFF 시 중지+mask만) | 서비스 불필요함이 확인된 후 |
| `vu_mask_rpcbind` | 🔴 NFS 연결단절 | U-42 rpcbind mask | 외부 NFS 마운트를 사용하지 않는 호스트만 |
| `vu_lock_extra_uid0` | 🔴 계정 잠금 | U-05 root 외 UID-0 계정 자동 격리(잠금+셸 제거) | 해당 계정이 불필요한지 확인 후 |
| `vu_apply_dup_uid` | 🔴 UID 변경 | U-10 중복 UID 재할당 (`vu_dup_uid_newvals` 매핑 필수) | UID 매핑표를 미리 준비한 후 |
| `vu_strip_world_writable` | 🟡 권한 변경 | U-25 세계쓰기 비트 자동 제거 | 파일 권한 검토 후 |
| `vu_del_ftp_pub_dir` | 🔴 데이터 삭제 | U-35 `/var/ftp/pub` 물리 삭제 | 디렉토리 내용 백업 후 |
| `vu_nfs_manage_exports` | 🔴 NFS 설정변경 | U-40 `/etc/exports` 재생성 | 내보내기 설정을 미리 준비한 후 |

### 기본 ON (저위험)

| 토글 | 설명 |
|------|------|
| `vu_quarantine_plain_hashes` | U-04 `/etc/passwd` 내 해시값 격리 |
| `vu_disable_plaintext_ftp` | U-54 cleartext FTP 서비스 중단(mask) |
| `vu_autopatch_security` | U-64 정기 보안 자동패치 (dnf-automatic / unattended-upgrades) |
| `vu_snmp_community_probe` | U-60 SNMP 공용 커뮤니티 문자열 보고용 프로브 |

---

## 주요 설정 변수

자주 사용하는 설정을 `defaults/main.yml`에서 확인하거나 실행 시 `-e`로 덮어쓸 수 있습니다.

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `vu_backups_root` | `/opt/backups/kisa_hardening` | 설정 파일 백업 위치 |
| `vu_tmout_sec` | `600` | 유휴 세션 타임아웃(초) — U-12 |
| `vu_umask` | `027` | 기본 UMASK — U-30 |
| `vu_encryption_method` | `SHA512` | 신규 계정 해시 알고리즘 — U-13 |
| `vu_pw_minlen` | `12` | 비밀번호 최소 길이 — U-02 |
| `vu_login_maxfails` | `5` | 로그인 실패 제한 횟수 — U-03 |
| `vu_login_unlock_time` | `900` | 잠금 해제 대기 시간(초) — U-03 |

---

## 점검 항목 카테고리

| 카테고리 | U-ID 범위 | 점검 영역 |
|----------|-----------|-----------|
| 계정 관리 | U-01 ~ U-13 | root 원격로그인, 비밀번호 정책, UID 중복, 유휴 세션 등 |
| 파일·디렉터리 관리 | U-14 ~ U-33 | 파일 권한, SUID/SGID, dot 파일, 홈 디렉터리 등 |
| 서비스 관리 | U-34 ~ U-62 | 불필요 서비스, FTP, NFS, SNMP, DNS 등 |
| 생명주기 관리 | U-63 ~ U-67 | 패치 관리, 감사로그, MOTD, 재부팅 정책 등 |
