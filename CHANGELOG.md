# CHANGELOG

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
