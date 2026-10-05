# KISA Linux Hardening — 취약점 감사·강화 플레이북

> **KISA(한국인터넷보안아카데미) 주요정보통신기반시설 기술적 취약점 분석·평가 상세가이드**에 맞춰 Linux 서버 67개 점검항목(U-01~U-67)을 Ansible로 자동화합니다.
>
> 읽기 전용 감사에서 실제 강화 적용까지 — 한 playbook으로 끝냅니다.

## 버전

| 태그 | 날짜 | 주요 내용 |
|------|------|----------|
| `v1.0.0` | 2026-09-29 | U-23 SUID/SGID 자동 제거, U-37 cron/at 권한, U-03 pam_tally2 제거 |

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
| Ubuntu 22.04 LTS | `ubuntu22` | unattended-upgrades, chrony, rsyslog, ssh.service |
| Ubuntu 24.04 LTS | `ubuntu24` | unattended-upgrades, chrony, journald, ssh.socket 대응 |

배포판별 패키지명, PAM 설정, 시스템 서비스 등의 차이는 `group_vars/<그룹>/`에서 자동 적용됩니다.

---

## 빠른 시작

### ① 읽기 전용 감사 (권장 시작)

시스템에 아무 변경 없이 "적합 여부만 점검"합니다. 결과는 `reports/<시간>/`에 저장됩니다.

```bash
# 전체 인벤토리 전수 감사
bash scripts/audit.sh

# 특정 배포그룹만 (al2023 / fedora / ubuntu22 / ubuntu24)
DISTRO=ubuntu22 bash scripts/audit.sh
DISTRO=ubuntu24 bash scripts/audit.sh

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

### ④ Vagrant VM 테스트 환경 (Ubuntu 22.04 / 24.04 LTS)

실제 가상머신 환경에서 완벽한 systemd/PAM/SSH 하드닝 동작을 검증할 수 있는 Vagrant 로컬 테스트 환경을 제공합니다.

#### 1) 테스트 환경 사양

| VM 이름 | 배포판 | 게스트 IP | 호스트 포트 | 기본 계정 | sudo 권한 |
|---------|--------|-----------|-------------|-----------|-----------|
| `ubuntu22` (`kisa-ubuntu22`) | Ubuntu 22.04 LTS | `192.168.56.22` | `2222` | `ubuntu` / `vagrant` | NOPASSWD |
| `ubuntu24` (`kisa-ubuntu24`) | Ubuntu 24.04 LTS | `192.168.56.24` | `2224` | `ubuntu` / `vagrant` | NOPASSWD |

* 호스트 머신의 SSH 키(`~/.ssh/id_ed25519.pub` 등)가 프로비저닝 시 자동으로 주입되어 별도 패스워드 없이 접속 가능합니다.

#### 2) 가상머신 라이프사이클 관리

```bash
# 전체 VM 기동 (Ubuntu 22 & 24)
vagrant up

# 특정 VM만 기동
vagrant up ubuntu22
vagrant up ubuntu24

# VM 상태 확인
vagrant status

# VM 일시 정지 / 중지
vagrant suspend
vagrant halt

# VM 완전 삭제 및 초기화
vagrant destroy -f
```

#### 3) SSH 터미널 직접 접속

호스트의 `~/.ssh/config`에 설정을 등록하면 터미널에서 호스트명만으로 즉시 접속할 수 있습니다:

```sshconfig
# ~/.ssh/config 예시
Host ubuntu22 kisa-ubuntu22
    HostName 127.0.0.1
    Port 2222
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.vagrant.d/insecure_private_keys/vagrant.key.ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host ubuntu24 kisa-ubuntu24
    HostName 127.0.0.1
    Port 2224
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.vagrant.d/insecure_private_keys/vagrant.key.ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

```bash
# SSH 바로 접속 (기본: ubuntu 계정)
ssh ubuntu22
ssh ubuntu24

# vagrant 계정으로 접속할 경우
ssh vagrant@ubuntu22
ssh vagrant@ubuntu24

# 또는 Vagrant CLI로 접속
vagrant ssh ubuntu22
vagrant ssh ubuntu24
```

#### 4) 원클릭 자동 감사 & 적용 스크립트

```bash
# Ubuntu 22 / 24 가상머신 기동 및 전수 감사 자동 수행
bash scripts/vagrant_test.sh

# 특정 배포판만 기동 및 감사
DISTRO=ubuntu22 bash scripts/vagrant_test.sh
DISTRO=ubuntu24 bash scripts/vagrant_test.sh

# 변경 사항 실제 적용 (미리보기 diff)
ACTION=apply DISTRO=ubuntu22 bash scripts/vagrant_test.sh
ACTION=apply DISTRO=ubuntu24 bash scripts/vagrant_test.sh
```

#### 5) Ansible 명령 직접 실행

```bash
# 연결 핑 테스트
ansible -i inventory/vagrant.ini all -m ping

# 감사 실행 (check 모드)
ansible-playbook -i inventory/vagrant.ini plays/site.yml --check

# Ubuntu 22에만 실제 적용
ansible-playbook -i inventory/vagrant.ini plays/site.yml -e distro_select=ubuntu22 --diff
```


---

## 프로젝트 구조

```
├── plays/
│   └── site.yml              # 진입점 (serial: 1, become: sudo)
├── roles/
│   └── kisa_linux_harden/
│       ├── defaults/
│       │   └── main.yml      # 전역 설정 변수 (U-01~U-67)
│       ├── handlers/
│       │   └── main.yml      # sshd reload 등 핸들러
│       └── tasks/
│           ├── 00_prep.yml   # 전처리: distro 감지, root 확인, 백업 준비
│           ├── main.yml      # 오케스트레이션 (모든 U-ID import)
│           ├── accounts/     # 계정 관리 (U-01~U-13)
│           ├── files/        # 파일·디렉터리 관리 (U-14~U-33)
│           ├── services/     # 서비스 관리 (U-34~U-62)
│           ├── lifecycle/    # 생명주기 관리 (U-63~U-67)
│           └── frags/        # 재사용 가능한 코드 조각
│               ├── file_perms.yml  # 파일 권한 설정 공통 패턴
│               └── unit_off.yml    # 서비스 중지+mask 공통 패턴
├── group_vars/
│   ├── al2023/main.yml       # Amazon Linux 2023 특화
│   ├── fedora/main.yml       # Fedora 특화
│   ├── ubuntu22/main.yml     # Ubuntu 22.04 LTS 특화
│   └── ubuntu24/main.yml     # Ubuntu 24.04 LTS 특화
├── inventory/
│   ├── ec2.example.ini       # EC2 인벤토리 예시
│   └── vagrant.ini           # Vagrant 로컬 VM 테스트 인벤토리
├── scripts/
│   ├── audit.sh              # 감사 래퍼 (--check --diff 강제, 리포트 자동 생성)
│   ├── report.py             # NDJSON → SUMMARY.md + detail.csv
│   ├── detect_contamination.py  # 외부 문자(CJK) 침투 검사
│   ├── fix_known_lines.py    # 문자 오염 패처 (역사적)
│   └── vagrant_test.sh       # Vagrant VM 기동 및 자동 감사/적용 래퍼
├── callbacks/
│   └── results_json.py       # NDJSON 이벤트 출력 콜백
├── ansible.cfg               # Ansible 설정
├── Vagrantfile               # Ubuntu 22 / 24 Multi-VM Vagrant 설정
├── _selftest/
│   ├── local.ini             # 로컬 스모크테스트 인벤토리
│   └── ubuntu.example.ini    # Ubuntu 전용 인벤토리 예시
├── reports/                  # 감사 산출물 (실행당 1개 디렉토리)
└── _source_ref/              # 기존 셸스크립트 감사기, 수동체크 가이드 (읽기 전용)
```

---

## 점검 항목

### 1장: 계정 관리 (U-01~U-13)

| ID | 항목 | 자동 조치 |
|----|------|-----------|
| U-01 | root 원격로그인 차단 | ✔ sshd_config 설정 |
| U-02 | 비밀번호 정책 (최대기간, 복잡도) | ✔ login.defs, pwquality |
| U-03 | 계정 잠금 임계값 | ✔ pam_faillock 설정 |
| U-04 | /etc/passwd 해시 격리 | ✔ 해시 제거+계정 잠금 |
| U-05 | UID-0 계정 격리 | 선택 (vu_lock_extra_uid0) |
| U-06 | su 접근 제한 (pam_wheel) | ✔ trust 제거, SUID 4750 |
| U-07 | 불필요 계정 삭제 | ✔ lp/uucp/nuucp/printadmin |
| U-08 | 관리자 그룹 최소화 | ✔ wheel 그룹 구성 |
| U-09 | 유령 GID 멤버십 정리 | ✔ 정리 |
| U-10 | 중복 UID 재할당 | 선택 (vu_apply_dup_uid) |
| U-11 | 시스템 계정 셸 nologin | ✔ nologin 설정 |
| U-12 | 유휴 세션 타임아웃 | ✔ TMOUT 설정 |
| U-13 | 해시 알고리즘 (yescrypt) | ✔ ENCRYPT_METHOD |

### 2장: 파일·디렉터리 관리 (U-14~U-33)

| ID | 항목 | 자동 조치 |
|----|------|-----------|
| U-14 | 환경 파일 권한 | ✔ 0644 |
| U-15 | 소유자 없는 파일 정리 | ✔ 삭제 |
| U-16 | /etc/passwd 계열 권한 | ✔ 0644/0600 |
| U-17 | 부트 스크립트 권한 | ✔ 0750 이하 |
| U-18 | /etc/shadow 권한 | ✔ 0600 |
| U-19 | /etc/hosts 계열 권한 | ✔ 0644 |
| U-20 | xinetd 설정 파일 권한 | ✔ 0644 |
| U-21 | syslog 설정 파일 권한 | ✔ 0644 |
| U-22 | /etc/services 파일 권한 | ✔ 0644 |
| U-23 | SUID/SGID 파일 감사 | ✔ whitelist 외 제거 |
| U-24 | 홈 디렉터리 환경 파일 권한 | ✔ 0644 |
| U-25 | 세계쓰기 파일 점검 | 선택 (vu_strip_world_writable) |
| U-26 | /dev 일반 파일 점검 | ✔ 리포트 |
| U-27 | r-commands 제거 | ✔ 삭제 |
| U-28 | 방화벽 설정 | 선택 (vu_manage_host_firewall) |
| U-29 | /etc/hosts.lpd 권한 | ✔ 0644 |
| U-30 | UMASK 정책 | ✔ 027 |
| U-31 | 홈 디렉터리 권한 | ✔ 0755 이하 |
| U-32 | 홈 디렉터리 존재 확인 | ✔ 생성 |
| U-33 | 숨김 파일(.dot) 점검 | ✔ 리포트 |

### 3장: 서비스 관리 (U-34~U-62)

| ID | 항목 | 자동 조치 |
|----|------|-----------|
| U-34 | finger 서비스 차단 | ✔ 중지+mask |
| U-35 | FTP/pub 디렉터리 삭제 | 선택 (vu_del_ftp_pub_dir) |
| U-36 | r-services 차단 | ✔ 중지+mask |
| U-37 | cron/at 접근 제어 | ✔ 파일 640, 바이너리 640 |
| U-38 | DoS 취약 서비스 차단 | ✔ 중지+mask |
| U-39 | NFS 차단 | ✔ 중지+mask |
| U-40 | NFS 접근 제어 | 선택 (vu_nfs_manage_exports) |
| U-41 | autofs 차단 | ✔ 중지+mask |
| U-42 | rpcbind 차단 | 선택 (vu_mask_rpcbind) |
| U-43 | NIS 차단 | ✔ 중지+mask |
| U-44 | tftp/talk 차단 | ✔ 중지+mask |
| U-45 | 메일 버전 노출 점검 | 리포트 |
| U-46 | 메일 실행 차단 | ✔ 설정 |
| U-47 | 스팸 중계 제한 | ✔ 설정 |
| U-48 | EXPN/VRFY 제한 | ✔ 설정 |
| U-49 | DNS 버전 노출 점검 | 리포트 |
| U-50 | DNS 존 전송 제한 | ✔ 설정 |
| U-51 | DNS 동적 업데이트 차단 | ✔ 설정 |
| U-52 | telnet 차단 | ✔ 중지+mask |
| U-53 | FTP 정보 숨김 | ✔ 설정 |
| U-54 | cleartext FTP 차단 | ✔ mask |
| U-55 | FTP 계정 셸 제한 | ✔ nologin |
| U-56 | FTP 접근 제어 | ✔ 설정 |
| U-57 | /etc/ftpusers 설정 | ✔ 설정 |
| U-58 | SNMP 데몬 차단 | ✔ 중지+mask |
| U-59 | SNMPv3 사용 권고 | 리포트 |
| U-60 | SNMP 커뮤니티 문자열 | ✔ 프로브 리포트 |
| U-61 | SNMP 접근 제어 | ✔ 설정 |
| U-62 | MOTD 경고 메시지 | ✔ 설정 |

### 4장~5장: 생명주기 관리 (U-63~U-67)

| ID | 항목 | 자동 조치 |
|----|------|-----------|
| U-63 | sudoers.d 권한 관리 | ✔ 0440 |
| U-64 | 자동 보안 패치 | ✔ dnf-automatic/unattended-upgrades |
| U-65 | 시간 동기화 (chrony) | ✔ chronyd |
| U-66 | 로깅 설정 | ✔ syslog |
| U-67 | /var/log 하위 권한 | ✔ 0640 |

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

### 태스크 이름 접두사

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
| `vu_encryption_method` | `yescrypt` | 신규 계정 해시 알고리즘 — U-13 |
| `vu_pw_minlen` | `12` | 비밀번호 최소 길이 — U-02 |
| `vu_login_maxfails` | `5` | 로그인 실패 제한 횟수 — U-03 |
| `vu_login_unlock_time` | `900` | 잠금 해제 대기 시간(초) — U-03 |
| `vu_home_dir_max_mode` | `755` | 홈 디렉터리 최대 권한 — U-31 |
| `vu_pass_max_days` | `90` | 비밀번호 최대 유효기간(일) — U-02 |
| `vu_trusted_suid_bins` | `['sudo']` | SUID whitelist (basename) — U-23 |
| `vu_scan_roots` | `[/etc, /usr/bin, /usr/sbin, /sbin, /bin, /home, /opt, /srv, /var/spool, /usr/local]` | SUID/SGID 스캔 경로 — U-23 |
