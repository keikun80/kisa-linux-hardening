# 🛡️ 주요정보통신기반시설 기술적 취약점 점검 도구 (Linux Server)

> **2026년 주요정보통신기반시설 기술적 취약점 분석·평가 방법 상세가이드 기반 자동 진단 스크립트**  
> KISA 가이드라인을 준수하여 Linux Server의 보안 취약점을 자동으로 점검하고 진단 보고서를 생성합니다.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Language-Shell%20Script-blue.svg)](https://www.gnu.org/software/bash/)
[![Compliance](https://img.shields.io/badge/Standard-KISA%20Guide%202026-green.svg)](https://www.kisa.or.kr/)

---

## 📖 프로젝트 소개

이 프로젝트는 **주요정보통신기반시설 기술적 취약점 점검 도구**로서, 한국인터넷진흥원(KISA)에서 배포한 **2026년 기술적 취약점 분석·평가 방법 상세가이드**의 유닉스(Linux) 서버 점검 항목(U-01 ~ U-67)을 구현한 Shell Script 솔루션입니다.

ISMS-P 인증 심사, 주요정보통신기반시설 취약점 점검 시 리눅스 서버(CentOS, Ubuntu, RHEL 등)의 보안 설정을 자동으로 진단하는 데 최적화되어 있습니다.

### 🎯 주요 활용 분야
*   **주요정보통신기반시설 기술적 취약점 분석·평가** 수행
*   **ISMS-P** (정보보호 및 개인정보보호 관리체계) 인증 심사 대비
*   **전자금융기반시설** 보안 취약점 점검
*   사내 리눅스 서버 보안 감사(Audit) 및 하드닝(Hardening)

## ✨ 주요 기능

*   **📜 가이드라인 완벽 준수:** 2026년 최신 가이드 기준 **U-01(계정 관리) ~ U-67(로그 관리)** 전체 항목 자동 점검.
*   **🐧 다양한 OS 지원:** CentOS, RHEL, Ubuntu, Debian 등 주요 리눅스 배포판 호환.
*   **📊 직관적인 결과 보고서:** 
    *   `취약(Vulnerable)`, `양호(Good)` 자동 판정.
    *   점검 결과를 텍스트 파일로 저장하여 손쉽게 확인 가능.
*   **⚡ Zero Dependency:** 별도의 프로그램 설치 없이 기본 **Shell(/bin/sh, /bin/bash)** 환경에서 즉시 실행.

## 🚀 사용 방법 (Usage)

### 1. 환경 준비
*   **대상 OS:** CentOS, RHEL, Ubuntu, Debian 등 Linux 계열
*   **필수 권한:** **root 권한** (시스템 설정 파일 및 로그 조회용)

### 2. 설치 및 실행

**Step 1. 스크립트 다운로드**
```bash
git clone https://github.com/SHyoJun/linux-vulnerability-check.git
cd linux-vulnerability-check
```

**Step 2. 실행 권한 부여**
```bash
chmod +x vulnerability_check_sh.sh
```

**Step 3. 점검 시작 (Root 권한 필요)**
```bash
sudo ./vulnerability_check_sh.sh
```

## 📝 진단 리포트 예시

점검이 완료되면 같은 폴더에 결과 파일이 생성됩니다.

*   `vulnerability_report_YYYYMMDD_HHMMSS.txt`: 요약 보고서
*   `vulnerability_detailed_report_YYYYMMDD_HHMMSS.txt`: 상세 보고서

```text
Linux 서버 취약점 점검 결과 (U-01 ~ U-67)
점검일시: 2026-01-27
OS: ubuntu
================================================================================
ID     | 점검 항목                                | 결과       | 상세 사유
--------------------------------------------------------------------------------
U-01   | root 계정 원격 접속 제한                  | 양호       | SSH PermitRootLogin no 설정됨
U-02   | 패스워드 복잡성 설정                      | 취약       | 복잡성 설정 미흡 (minlen=8 미충족)
...
U-67   | 로그 디렉터리 소유자 및 권한 설정           | 양호       | 소유자 root, 권한 755 이하
================================================================================
```

## 🔍 수동 점검 가이드 (Manual Check Guide)

자동 점검 결과에 대한 검증이나 상세한 점검 방법이 필요한 경우, 아래 수동 점검 가이드를 참고하세요.
각 항목별로 **명령어 입력 방법**과 **양호/취약 판단 기준**이 상세히 기술되어 있습니다.

*   👉 [**Manual_Check_Guide_Linux.md**](Manual_Check_Guide_Linux.md)

## 📂 파일 구조

```
.
├── vulnerability_check_sh.sh         # 🌟 메인 점검 스크립트
├── Manual_Check_Guide_Linux.md       # 🔍 수동 점검 가이드
└── README.md                         # 설명서
```

## ⚠️ 면책 조항 (Disclaimer)

*   이 도구는 보안 점검을 돕기 위한 보조 도구입니다. 최종적인 보안 적합성 판단은 보안 전문가의 검토가 필요할 수 있습니다.
*   시스템 설정을 변경(Write)하지 않고 조회(Read)만 수행하므로 안전하지만, 중요 서버에서는 테스트 후 실행을 권장합니다.

## 🤝 기여 (Contribution)

이 프로젝트는 오픈 소스입니다. 이슈 제보 및 PR은 언제나 환영합니다.
*   **관련 키워드:** `주요정보통신기반시설`, `취약점 점검`, `KISA`, `Linux Server`, `Shell Script`, `ISMS-P`
