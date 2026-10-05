# CHANGELOG

## v1.1.0 (2026-10-05)

### Added

- **Ubuntu 22.04 LTS 및 Ubuntu 24.04 LTS 전용 프로파일 이분화**:
  - `group_vars/ubuntu22/main.yml`: Ubuntu 22.04 LTS 프로파일 (`ssh.service`, `rsyslog`, SUID 화이트리스트 등)
  - `group_vars/ubuntu24/main.yml`: Ubuntu 24.04 LTS 프로파일 (`ssh.socket` 대응, `journald` 중심 로깅 등)
  - 인벤토리(`inventory/ec2.ini`, `ec2.example.ini`)의 `ubuntu`를 `ubuntu22` 및 `ubuntu24`로 분리
  - `scripts/audit.sh` 및 `plays/site.yml`의 `DISTRO` 선택 목록에 `ubuntu22`, `ubuntu24` 추가
  - `_selftest/ubuntu.example.ini`: 로컬 컨테이너/VM 테스트용 인벤토리 예시 추가
  - `Vagrantfile`: Ubuntu 22.04 LTS 및 24.04 LTS 멀티 VM 테스트 환경 구성
  - `inventory/vagrant.ini`: Vagrant 전용 Ansible 인벤토리 추가
  - `scripts/vagrant_test.sh`: Vagrant 기동부터 감사/적용까지 원클릭 래퍼 스크립트 제공

### Changed & Fixed

- **00_prep.yml**:
  - `vu_wheel_gid`: `wheel` 그룹뿐만 아니라 Ubuntu의 `sudo` 관리자 그룹 GID 자동 조회 지원
  - `vu_sshd_unit_exists`: `sshd.service`뿐만 아니라 `ssh.service`, `ssh.socket` 유닛 자동 감지 및 서비스명 확정 로직 추가
- **handlers/main.yml**:
  - SSH 리로드 시 `vu_sshd_service_name` 동적 반영 및 systemd socket activation 환경을 위한 fallback 로직 추가
- **U-02**:
  - `file_stat` 미정의 오류 방지를 위한 정적 `stat` 검사 적용
  - `libpam-pwquality` 패키지 및 Debian `common-password` 존재 검사 보강
- **U-03**:
  - Debian/Ubuntu 계열의 `common-auth` 및 `common-account` 파일 검사 및 `pam_faillock` 안전 주입
- **U-66**:
  - `vu_logging_service` 변수 연동 (`rsyslog` vs `journald`) 및 조건 분기 안정화

## v1.0.1 (2026-09-29)

### Fixed

- **U-63**: `/etc/sudoers.d/99-docker-appexec` 파일이 존재하지 않을 때 실행 중단되는 문제 수정 ([05e4bda](https://github.com/keikun80/kisa-linux-hardening/commit/05e4bda))
  - `required: true` → `required: false`로 변경하여 파일 부재 시 skip 처리

### Docs

- README 업데이트: 프로젝트 구조, 점검 항목 테이블, 버전 정보 추가 ([663438b](https://github.com/keikun80/kisa-linux-hardening/commit/663438b))

## v1.0.0 (2026-09-15)

초기 릴리스. KISA 보안 강화 가이드라인 (U-01 ~ U-67) 기반 Ansible hardening 역할.

- **U-02**: 비밀번호 유효기간, pwquality 설정 (`enforce_for_root`, 패키지명 정정)
- **U-03**: pam_tally2 설정 삭제 (pam_faillock 표준 사용)
- **U-04**: 네트워크 리스커닝 서비스 관리
- **U-06**: `pam.d/su` trust 옵션 제거, sudo/wheel 그룹 제한
- **U-07**: 불필요 계정 (lp, uucp, nuucp, printadmin) 삭제, 서비스 계정 nologin 처리 제거
- **U-08**: 불필요 서비스 차단
- **U-11**: `vu_system_accounts` 서비스 계정 분리 관리
- **U-13**: ENCRYPT_METHOD를 yescrypt로 변경, SHA256 강등
- **U-15**: `/var/spool/mail` 하위 파일/디렉토리 자동 삭제
- **U-23**: SUID/SGID 자동 제거 (whitelist 기반: `sudo` 만 허용, `ksu` 제거)
- **U-37**: cron/at 바이너리 권한 관리 (640), `/usr/bin/crontab` 추가
- **U-63**: `/etc/sudoers`, `/etc/sudoers.d/99-docker-appexec` 권한 440 적용
- **U-64**: 자동패치 (dnf-automatic) 관리
- **U-66**: journald 지원
- **U-67**: `/var/log` 하위 파일 권한 640 적용
