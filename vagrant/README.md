# KISA Linux Hardening — Vagrant 테스트 및 이미지 빌드 환경

이 디렉토리는 KISA 리눅스 보안 가이드(U-01~U-67)의 자동화 및 검증을 위한 **로컬 멀티 VM 테스트 환경 및 이미지 패키징 도구 모음**입니다.

---

## 📁 디렉터리 구성

| 파일/폴더 | 설명 |
|---|---|
| [`Vagrantfile`](file:///home/keikun/project/kisa-linux-hardening/vagrant/Vagrantfile) | 6개 배포판(AL2023, Fedora, Rocky 8/9, Ubuntu 22/24) VM 정의 파일 |
| [`init.sh`](file:///home/keikun/project/kisa-linux-hardening/vagrant/init.sh) | Vagrant VM 완전 초기화 및 신규 생성 스크립트 |
| [`build_image.sh`](file:///home/keikun/project/kisa-linux-hardening/vagrant/build_image.sh) | VM을 `.box` 이미지로 패키징/내보내기 (하드닝 적용 옵션 포함) |
| [`test.sh`](file:///home/keikun/project/kisa-linux-hardening/vagrant/test.sh) | VM 대상 KISA 감사(audit) 및 실제 적용(apply) 실행 스크립트 |
| [`inventory.ini`](file:///home/keikun/project/kisa-linux-hardening/vagrant/inventory.ini) | Vagrant VM 전용 Ansible 인벤토리 설정 파일 |
| `images/` | `build_image.sh`로 빌드된 `.box` 이미지 파일 저장소 (자동 생성) |

---

---

## 🔄 Vagrant 테스트 및 하드닝 권장 순서

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  1. 초기화   │ ──> │ 2. 사전 감사 │ ──> │  3. 하드닝   │ ──> │ 4. 사후 검증 │ ──> │ 5. 이미지    │
│  (init.sh)   │     │  (Audit #1)  │     │ 적용 (Apply) │     │  (Audit #2)  │     │ 빌드(선택)   │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

### [Step 1] 테스트 VM 초기화 및 깨끗한 환경 기동
기존 가상머신을 완전히 초기화(`destroy`)하고 새롭게 기동(`up`)합니다.
```bash
# 전체 VM 초기화 및 기동
bash vagrant/init.sh

# 또는 특정 배포판만 초기화 (예: Ubuntu 22.04)
bash vagrant/init.sh ubuntu22
```

### [Step 2] 하드닝 적용 전 사전 감사 (Baseline Audit)
설정 변경 없이 현재 기본 OS의 취약점 상태를 측정합니다. 리포트는 `reports/<타임스탬프>/`에 자동 생성됩니다.
```bash
# 전체 VM 감사
bash vagrant/test.sh

# 특정 배포판만 감사
bash vagrant/test.sh ubuntu22
```

### [Step 3] KISA 보안 하드닝 실제 적용 (Apply Hardening)
67개 KISA 점검 항목에 대한 보안 설정을 가상머신에 실제 적용합니다.
```bash
# 특정 배포판에 하드닝 적용
ACTION=apply bash vagrant/test.sh ubuntu22

# 전체 배포판에 하드닝 적용
ACTION=apply bash vagrant/test.sh
```

### [Step 4] 하드닝 적용 후 사후 검증 (Verification Audit)
감사를 재수행하여 이전 단계에서 지적된 취약점(✗ / ▲)이 정상(·)으로 해결되었는지 최종 검증합니다.
```bash
bash vagrant/test.sh ubuntu22
```

### [Step 5] (선택) 검증된 강화 골든 이미지 패키징
하드닝 및 검증이 완료된 가상머신을 재사용 가능한 `.box` 이미지로 빌드합니다.
```bash
# 골든 이미지 패키징
bash vagrant/build_image.sh ubuntu22

# KISA 하드닝 선적용 옵션을 포함하여 패키징할 경우
APPLY_HARDENING=1 bash vagrant/build_image.sh ubuntu22
```
생성된 이미지는 `vagrant/images/`에 저장되며, `vagrant box add` 명령어로 로컬에 등록할 수 있습니다:
```bash
vagrant box add kisa/ubuntu22-hardened vagrant/images/kisa-ubuntu22-hardened-latest.box
```

### [Step 6] 테스트 종료 후 VM 정리
```bash
cd vagrant

# VM 일시 정지 / 중지
vagrant halt ubuntu22

# VM 완전 삭제
vagrant destroy -f ubuntu22
```

---

## 🖥 가상머신 사양 및 접속 정보

| VM 이름 | 배포판 | 게스트 IP | 호스트 포트 | 기본 계정 | sudo 권한 |
|---------|--------|-----------|-------------|-----------|-----------|
| `al2023` | Amazon Linux 2023 | `192.168.56.23` | `2223` | `ec2-user` / `vagrant` | NOPASSWD |
| `fedora` | Fedora 41 | `192.168.56.41` | `2241` | `fedora` / `vagrant` | NOPASSWD |
| `rocky8` | Rocky Linux 8 | `192.168.56.8` | `2208` | `rocky` / `vagrant` | NOPASSWD |
| `rocky9` | Rocky Linux 9 | `192.168.56.9` | `2209` | `rocky` / `vagrant` | NOPASSWD |
| `ubuntu22` | Ubuntu 22.04 LTS | `192.168.56.22` | `2222` | `ubuntu` / `vagrant` | NOPASSWD |
| `ubuntu24` | Ubuntu 24.04 LTS | `192.168.56.24` | `2224` | `ubuntu` / `vagrant` | NOPASSWD |

```bash
# SSH 접속 (vagrant 디렉토리 기준)
cd vagrant
vagrant ssh al2023
vagrant ssh fedora
vagrant ssh rocky8
vagrant ssh rocky9
vagrant ssh ubuntu22
vagrant ssh ubuntu24
```
