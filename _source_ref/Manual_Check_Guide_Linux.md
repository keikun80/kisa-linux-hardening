# Linux Server 보안 취약점 수동 점검 가이드 (최종 정밀판 v3.1)

본 가이드는 KISA '주요정보통신기반시설 기술적 취약점 분석·평가 방법 상세가이드(2026)'를 기준으로 작성되었으며, 자동 점검 스크립트의 결과(특히 '수동점검' 항목)를 보완하기 위한 관리자용 가이드입니다.

---

## 1. 계정 관리

### U-01 root 계정 원격 접속 제한
*   **점검 명령어:**
    ```bash
    grep "^PermitRootLogin" /etc/ssh/sshd_config
    cat /etc/securetty | grep "pts"
    ```
*   **판단 기준:**
    *   **양호:** `PermitRootLogin no` 설정됨, `securetty` 파일에 `pts/x` 설정 없음.
    *   **취약:** `PermitRootLogin yes` 또는 설정 없음, `securetty`에 `pts/x` 존재.

### U-02 비밀번호 관리정책 설정
*   **점검 명령어:**
    ```bash
    # RHEL/CentOS
    cat /etc/security/pwquality.conf
    # Ubuntu/Debian
    grep "pam_pwquality.so" /etc/pam.d/common-password
    ```
*   **판단 기준:**
    *   **양호:** `minlen`(8 이상), `lcredit`, `ucredit`, `dcredit`, `ocredit` 중 2개 이상 설정(-1)됨.
    *   **취약:** 복잡성 설정이 없거나 기준 미달.

### U-03 계정 잠금 임계값 설정
*   **점검 명령어:**
    ```bash
    grep -E "pam_tally2|pam_faillock" /etc/pam.d/system-auth /etc/pam.d/password-auth /etc/pam.d/common-auth
    ```
*   **판단 기준:**
    *   **양호:** `deny=5` (또는 10 이하) 설정 확인.
    *   **취약:** `deny` 옵션이 없거나 10회 초과.

### U-04 비밀번호 파일 보호
*   **점검 명령어:**
    ```bash
    head -n 1 /etc/passwd
    ls -l /etc/shadow
    ```
*   **판단 기준:**
    *   **양호:** `/etc/passwd`의 두 번째 필드가 `x`, `/etc/shadow` 파일 존재.
    *   **취약:** `/etc/passwd`에 암호 해시 노출, `/etc/shadow` 없음.

### U-05 root 이외의 UID '0' 금지
*   **점검 명령어:**
    ```bash
    awk -F: '$3==0 {print $1}' /etc/passwd
    ```
*   **판단 기준:**
    *   **양호:** `root` 계정만 출력됨.
    *   **취약:** `root` 이외의 계정이 출력됨.

### U-06 사용자 계정 su 기능 제한
*   **점검 명령어:**
    ```bash
    grep "pam_wheel.so" /etc/pam.d/su
    ls -l /usr/bin/su
    ```
*   **판단 기준:**
    *   **양호:** `pam_wheel.so` 설정 존재(주석 해제) 또는 `su` 실행 권한이 특정 그룹(4750)에만 있음.
    *   **취약:** 누구나 `su` 명령 사용 가능.

### U-07 불필요한 계정 제거 (관리자 판단 필요)
*   **점검 내용:** 시스템 운영에 불필요한 계정(퇴사자, 미사용, 기본 계정 등) 존재 여부 확인.
*   **점검 명령어:**
    ```bash
    cat /etc/passwd
    # 로그인 가능한 쉘(/bin/bash 등)을 가진 계정 확인
    cat /etc/passwd | grep -v "nologin\|false"
    ```
*   **판단 기준:**
    *   **양호:** 불필요한 계정이 없거나, 로그인이 불가능한 쉘(`/bin/false` 등)로 설정됨.
    *   **취약:** 사용하지 않는 계정이 로그인 가능한 쉘을 가지고 있거나 삭제되지 않음.

### U-08 관리자 그룹에 최소한의 계정 포함
*   **점검 내용:** 관리자 그룹(root)에 불필요한 계정이 포함되어 있는지 확인.
*   **점검 명령어:**
    ```bash
    grep "^root:" /etc/group
    ```
*   **판단 기준:**
    *   **양호:** root 그룹에 불필요한 계정이 없음.
    *   **취약:** root 그룹에 불필요한 계정이 포함됨.

### U-09 계정이 존재하지 않는 GID 금지
*   **점검 내용:** `/etc/group` 파일에 존재하지 않는 계정을 가진 그룹이 있는지 확인.
*   **점검 명령어:**
    ```bash
    grpck
    # 또는 수동 확인
    cat /etc/group
    ```
*   **판단 기준:**
    *   **양호:** 존재하지 않는 계정을 포함한 그룹이 없음.
    *   **취약:** 존재하지 않는 계정이 그룹에 포함되어 있음.

### U-10 동일한 UID 금지
*   **점검 내용:** UID가 동일한 사용자 계정이 존재하는지 확인.
*   **점검 명령어:**
    ```bash
    awk -F: '{print $3}' /etc/passwd | sort | uniq -d
    ```
*   **판단 기준:**
    *   **양호:** 중복된 UID가 출력되지 않음.
    *   **취약:** 중복된 UID가 출력됨.

### U-11 사용자 Shell 점검
*   **점검 내용:** 로그인이 필요 없는 시스템 계정에 로그인 쉘이 부여되어 있는지 확인.
*   **점검 명령어:**
    ```bash
    # 시스템 계정 (daemon, bin, sys 등)의 쉘 확인
    cat /etc/passwd | grep -E "^(daemon|bin|sys|adm|lp|uucp|nuucp)"
    ```
*   **판단 기준:**
    *   **양호:** 쉘이 `/bin/false` 또는 `/sbin/nologin`으로 설정됨.
    *   **취약:** `/bin/bash` 또는 `/bin/sh` 등으로 설정됨.

### U-12 세션 종료 시간 설정
*   **점검 내용:** 일정 시간 유휴 상태일 경우 세션 자동 로그아웃 설정 여부.
*   **점검 명령어:**
    ```bash
    grep "TMOUT" /etc/profile /etc/bashrc
    echo $TMOUT
    ```
*   **판단 기준:**
    *   **양호:** `TMOUT=600` (600초 이하) 설정 확인.
    *   **취약:** 설정이 없거나 600초 초과.

### U-13 안전한 비밀번호 암호화 알고리즘 사용
*   **점검 내용:** 쉐도우 파일 암호화 알고리즘이 안전한 방식(SHA-512 등)인지 확인.
*   **점검 명령어:**
    ```bash
    grep "ENCRYPT_METHOD" /etc/login.defs
    # 또는 실제 적용된 해시 확인 ($6$ = SHA-512)
    head -1 /etc/shadow
    ```
*   **판단 기준:**
    *   **양호:** SHA-512 (또는 SHA-256) 알고리즘 사용.
    *   **취약:** MD5($1$) 등 취약한 알고리즘 사용.

---

## 2. 파일 및 디렉토리 관리

### U-14 사용자, 시스템 환경변수 파일 소유자 및 권한 설정
*   **점검 내용:** 환경변수 설정 파일 변조 방지.
*   **점검 명령어:**
    ```bash
    ls -l /etc/profile /etc/bashrc /home/*/.bashrc
    ```
*   **판단 기준:**
    *   **양호:** 소유자가 root 또는 해당 사용자이고, 타인 쓰기 권한이 없음.
    *   **취약:** 타인이 수정 가능함(w 권한).

### U-15 파일 및 디렉터리 소유자 설정
*   **점검 내용:** 소유자가 존재하지 않는 파일(nouser, nogroup) 확인.
*   **점검 명령어:**
    ```bash
    find / -nouser -o -nogroup 2>/dev/null
    ```
*   **판단 기준:**
    *   **양호:** 소유자가 없는 파일이 없음.
    *   **취약:** 소유자가 없는 파일이 존재함.

### U-16 /etc/passwd 파일 소유자 및 권한 설정
*   **점검 내용:** 중요 파일 권한 관리.
*   **점검 명령어:**
    ```bash
    ls -l /etc/passwd
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 644 (`-rw-r--r--`).
    *   **취약:** 권한이 644보다 높음 (예: 666).

### U-17 시스템 시작 스크립트 권한 설정
*   **점검 내용:** 부팅 시 실행되는 스크립트 권한 관리.
*   **점검 명령어:**
    ```bash
    ls -l /etc/rc.d/init.d/
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 755 이하.
    *   **취약:** 일반 사용자에게 쓰기 권한 있음.

### U-18 /etc/shadow 파일 소유자 및 권한 설정
*   **점검 내용:** 암호 파일 유출 방지.
*   **점검 명령어:**
    ```bash
    ls -l /etc/shadow
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 400 (`-r--------`) 또는 000.
    *   **취약:** 권한이 400보다 높음(예: 600, 644).

### U-19 /etc/hosts 파일 소유자 및 권한 설정
*   **점검 내용:** 호스트 파일 변조 방지.
*   **점검 명령어:**
    ```bash
    ls -l /etc/hosts
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 600 또는 644.
    *   **취약:** 일반 사용자에게 쓰기 권한 있음.

### U-20 /etc/(x)inetd.conf 파일 소유자 및 권한 설정
*   **점검 내용:** 서비스 설정 파일 변조 방지.
*   **점검 명령어:**
    ```bash
    ls -l /etc/xinetd.conf /etc/inetd.conf 2>/dev/null
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 600.
    *   **취약:** 권한이 600보다 높음.

### U-21 /etc/(r)syslog.conf 파일 소유자 및 권한 설정
*   **점검 내용:** 로그 설정 파일 권한 관리.
*   **점검 명령어:**
    ```bash
    ls -l /etc/rsyslog.conf /etc/syslog.conf 2>/dev/null
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 640.
    *   **취약:** 권한이 640보다 높음.

### U-22 /etc/services 파일 소유자 및 권한 설정
*   **점검 내용:** 포트 설정 파일 권한 관리.
*   **점검 명령어:**
    ```bash
    ls -l /etc/services
    ```
*   **판단 기준:**
    *   **양호:** 소유자 root, 권한 644.
    *   **취약:** 일반 사용자에게 쓰기 권한 있음.

### U-23 SUID, SGID, Sticky bit 설정 파일 점검
*   **점검 내용:** 특수 권한이 설정된 파일 점검.
*   **점검 명령어:**
    ```bash
    find / -user root -type f \( -perm -04000 -o -perm -02000 \) -xdev -ls
    ```
*   **판단 기준:**
    *   **양호:** 불필요한 파일에 SUID/SGID가 설정되어 있지 않음.
    *   **취약:** 불필요하거나 의심스러운 파일에 설정됨.

### U-24 사용자, 시스템 환경변수 파일 소유자 및 권한 설정
*   (U-14와 중복되는 경우가 많으나 가이드상 별도 존재 시 재확인)
*   **점검 내용:** 홈 디렉토리 환경 파일 권한.
*   **점검 명령어:**
    ```bash
    ls -l /etc/profile /home/*/.bashrc
    ```
*   **판단 기준:**
    *   **양호:** 소유자 본인, 타인 쓰기 권한 없음.

### U-25 World Writable 파일 점검
*   **점검 내용:** 누구나 쓸 수 있는 파일 점검.
*   **점검 명령어:**
    ```bash
    find / -type f -perm -2 -exec ls -l {} \;
    ```
*   **판단 기준:**
    *   **양호:** 시스템상 필요한 파일 외 World Writable 파일 없음.
    *   **취약:** 중요 설정 파일 등이 World Writable 상태임.

### U-26 /dev에 존재하지 않는 device 파일 점검
*   **점검 내용:** /dev 디렉터리에 일반 파일 존재 여부.
*   **점검 명령어:**
    ```bash
    find /dev -type f -exec ls -l {} \;
    ```
*   **판단 기준:**
    *   **양호:** 장치 파일 외 일반 파일이 없음.
    *   **취약:** 일반 파일이 존재함 (악성코드 은닉 가능성).

### U-27 r-command 사용 금지
*   **점검 내용:** 인증 없이 접속 가능한 r-command 서비스 차단.
*   **점검 명령어:**
    ```bash
    ls -l /etc/hosts.equiv $HOME/.rhosts 2>/dev/null
    systemctl list-unit-files | grep -E "rsh|rlogin|rexec"
    ```
*   **판단 기준:**
    *   **양호:** 설정 파일이 없거나 서비스가 비활성화됨.
    *   **취약:** 설정 파일에 `+`가 있거나 서비스 실행 중.

### U-28 접속 IP 및 포트 제한
*   **점검 내용:** TCP Wrapper 또는 방화벽 사용 여부.
*   **점검 명령어:**
    ```bash
    cat /etc/hosts.deny
    iptables -L
    ufw status
    ```
*   **판단 기준:**
    *   **양호:** `hosts.deny`에 `ALL:ALL` 설정 또는 방화벽 정책 존재.
    *   **취약:** 접근 제어 설정이 없음.

### U-29 hosts.lpd 파일 소유자 및 권한 설정
*   **점검 내용:** 프린터 서비스 설정 파일 권한.
*   **점검 명령어:**
    ```bash
    ls -l /etc/hosts.lpd
    ```
*   **판단 기준:**
    *   **양호:** 파일 없음 또는 권한 600.
    *   **취약:** 권한 600 초과.

### U-30 UMASK 설정 관리
*   **점검 내용:** 기본 파일 생성 권한 마스크 설정.
*   **점검 명령어:**
    ```bash
    grep "umask" /etc/profile /etc/bashrc
    ```
*   **판단 기준:**
    *   **양호:** 022 이상 (022, 027 등).
    *   **취약:** 022 미만 (002 등).

### U-31 홈 디렉토리 소유자 및 권한 설정
*   **점검 내용:** 사용자 홈 디렉터리 권한.
*   **점검 명령어:**
    ```bash
    ls -ld /home/*
    ```
*   **판단 기준:**
    *   **양호:** 타 사용자 쓰기 권한 없음 (755 이하).
    *   **취약:** 타 사용자 쓰기 권한 있음 (777 등).

### U-32 홈 디렉토리로 지정한 디렉토리의 존재 관리
*   **점검 내용:** 계정의 홈 디렉터리가 실제 존재하는지 확인.
*   **점검 명령어:**
    ```bash
    awk -F: '{print $6}' /etc/passwd | while read d; do [ ! -d "$d" ] && echo "$d missing"; done
    ```
*   **판단 기준:**
    *   **양호:** 누락된 디렉터리 없음.
    *   **취약:** 홈 디렉터리가 없는 계정이 존재.

### U-33 숨겨진 파일 및 디렉토리 검색 및 제거
*   **점검 내용:** 불필요한 숨김 파일(`.`으로 시작) 점검.
*   **점검 명령어:**
    ```bash
    find / -name ".*" -print
    ```
*   **판단 기준:**
    *   **양호:** 불필요한 숨김 파일이 없음.
    *   **취약:** 의심스러운 숨김 파일 발견.

---

## 3. 서비스 관리

### U-34 Finger 서비스 비활성화
*   **점검 명령어:** `ps -ef | grep finger`
*   **판단 기준:** 미실행.

### U-35 공유 서비스에 대한 익명 접근 제한 설정
*   **점검 명령어:** `grep "anonymous_enable" /etc/vsftpd/vsftpd.conf`
*   **판단 기준:** `NO` 설정.

### U-36 r 계열 서비스 비활성화
*   **점검 명령어:** `ps -ef | grep -E "rsh|rlogin|rexec"`
*   **판단 기준:** 미실행.

### U-37 crontab 설정파일 권한 설정 미흡
*   **점검 명령어:** `ls -l /etc/cron.allow`
*   **판단 기준:** 권한 640 이하.

### U-38 DoS 공격에 취약한 서비스 비활성화
*   **점검 내용:** echo, discard 등 비활성화.
*   **점검 명령어:**
    ```bash
    grep "disable" /etc/xinetd.d/echo
    ```
*   **판단 기준:** `yes` 설정 또는 파일 없음.

### U-39 불필요한 NFS 서비스 비활성화
*   **점검 명령어:** `ps -ef | grep nfs`
*   **판단 기준:** 미실행.

### U-40 NFS 접근 통제
*   **점검 명령어:** `cat /etc/exports`
*   **판단 기준:** 접근 IP가 제한됨 (전체 허용 `*` 없음).

### U-41 불필요한 automountd 제거
*   **점검 명령어:** `ps -ef | grep automount`
*   **판단 기준:** 미실행.

### U-42 불필요한 RPC 서비스 비활성화
*   **점검 명령어:** `rpcinfo -p`
*   **판단 기준:** 불필요 서비스 없음.

### U-43 NIS, NIS+ 점검
*   **점검 명령어:** `ps -ef | grep ypserv`
*   **판단 기준:** 미실행.

### U-44 tftp, talk 서비스 비활성화
*   **점검 명령어:** `ls -l /etc/xinetd.d/tftp`
*   **판단 기준:** `disable = yes` 또는 파일 없음.

### U-45 메일 서비스 버전 점검
*   **점검 명령어:** `sendmail -d0.1 < /dev/null | grep Version`
*   **판단 기준:** 최신 버전.

### U-46 일반 사용자의 메일 서비스 실행 방지
*   **점검 명령어:** `grep "restrictqrun" /etc/mail/sendmail.cf`
*   **판단 기준:** 설정됨.

### U-47 스팸 메일 릴레이 제한
*   **점검 명령어:** `grep "Relaying denied" /etc/mail/sendmail.cf`
*   **판단 기준:** 설정됨.

### U-48 expn, vrfy 명령어 제한
*   **점검 명령어:** `grep "PrivacyOptions" /etc/mail/sendmail.cf`
*   **판단 기준:** `noexpn`, `novrfy` 설정됨.

### U-49 DNS 보안 버전 패치
*   **점검 명령어:** `named -v`
*   **판단 기준:** 최신 버전.

### U-50 DNS Zone Transfer 설정
*   **점검 명령어:** `grep "allow-transfer" /etc/named.conf`
*   **판단 기준:** 제한됨 (특정 IP 또는 none).

### U-51 DNS 서비스의 취약한 동적 업데이트 설정 금지
*   **점검 명령어:** `grep "allow-update" /etc/named.conf`
*   **판단 기준:** `none`.

### U-52 Telnet 서비스 비활성화
*   **점검 명령어:** `netstat -an | grep ":23 "`
*   **판단 기준:** 미실행 (리스닝 포트 없음).

### U-53 FTP 서비스 정보 노출 제한
*   **점검 명령어:** `grep "ftpd_banner" /etc/vsftpd/vsftpd.conf`
*   **판단 기준:** 배너 숨김 설정 또는 파일 없음.

### U-54 암호화되지 않는 FTP 서비스 비활성화
*   **점검 명령어:** `ps -ef | grep ftp`
*   **판단 기준:** 미실행 (SFTP 사용 권장).

### U-55 FTP 계정 Shell 제한
*   **점검 명령어:** `grep "^ftp:" /etc/passwd`
*   **판단 기준:** `/bin/false` 또는 `/sbin/nologin`.

### U-56 FTP 서비스 접근 제어 설정
*   **점검 내용:** `ftpusers`, `user_list` 등을 통한 접근 제어 확인.
*   **점검 명령어:**
    ```bash
    ls -l /etc/vsftpd/ftpusers /etc/vsftpd.user_list
    cat /etc/vsftpd/ftpusers
    ```
*   **판단 기준:** 파일이 존재하고 접근 제어 목록이 설정되어 있음.

### U-57 Ftpusers 파일 설정
*   **점검 내용:** root 계정 접속 차단 여부.
*   **점검 명령어:** `grep "root" /etc/vsftpd/ftpusers`
*   **판단 기준:** root 계정이 목록에 포함됨.

### U-58 불필요한 SNMP 서비스 구동 점검
*   **점검 명령어:** `ps -ef | grep snmp`
*   **판단 기준:** 미실행.

### U-59 안전한 SNMP 버전 사용
*   **점검 내용:** SNMP v3 사용.
*   **판단 기준:** v3 사용 (v1, v2c 사용 시 취약).

### U-60 SNMP Community String 복잡성 설정
*   **점검 내용:** public/private 사용 금지.
*   **점검 명령어:** `grep -E "public|private" /etc/snmp/snmpd.conf`
*   **판단 기준:** 해당 문자열 없음.

### U-61 SNMP Access Control 설정
*   **점검 내용:** 접근 IP 제한.
*   **점검 명령어:** `grep "com2sec" /etc/snmp/snmpd.conf`
*   **판단 기준:** 제한됨 (특정 IP/Network).

### U-62 로그인 시 경고 메시지 설정
*   **점검 명령어:** `cat /etc/motd`
*   **판단 기준:** 내용 존재.

### U-63 sudo 명령어 접근 관리
*   **점검 명령어:** `ls -l /etc/sudoers`
*   **판단 기준:** 권한 440.

---

## 4. 패치 관리

### U-64 주기적 보안 패치 및 벤더 권고사항 적용
*   **점검 명령어:** `yum check-update` (RHEL) / `apt list --upgradable` (Debian)
*   **판단 기준:** 최신 패치 적용됨 (업데이트 목록 없음).

---

## 5. 로그 관리

### U-65 NTP 및 시각 동기화 설정
*   **점검 명령어:** `ps -ef | grep -E "ntp|chrony"`
*   **판단 기준:** 실행 중.

### U-66 정책에 따른 시스템 로깅 설정
*   **점검 명령어:** `ls -l /etc/rsyslog.conf`
*   **판단 기준:** 파일 존재.

### U-67 로그 디렉터리 소유자 및 권한 설정
*   **점검 명령어:** `ls -ld /var/log`
*   **판단 기준:** 권한 755 이하.
