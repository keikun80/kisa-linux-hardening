# KISA Linux Hardening — AWS 테스트 인프라 (Terraform)

이 디렉토리는 AWS 환경에서 KISA 리눅스 보안 가이드(U-01~U-67)를 대규모/실제 클라우드 환경에서 테스트하기 위한 **Terraform 인프라 자동화 도구 모음**입니다.

1대의 **Admin 노드(Ansible 컨트롤러)**와 **6개 타깃 OS 노드**로 구성된 전용 VPC 환경을 자동으로 프로비저닝합니다.

---

## 🏗 인프라 아키텍처

```
                                    [AWS VPC: 10.10.0.0/16]
                                 Public Subnet (10.10.1.0/24)
                            ┌───────────────────────────────────┐
                            │                                   │
[호스트 머신] ──(SSH)───> │  ★ Admin Node (Ubuntu 24.04)     │
                            │    (Ansible Control Node)         │
                            │    - Private IP: 10.10.1.x        │
                            │    - Public IP 자동 할당          │
                            │                                   │
                            └─────────────────┬─────────────────┘
                                              │ (Ansible 제어 / SSH)
                            ┌─────────────────▼─────────────────┐
                            │  [Target OS Test Nodes]           │
                            │  ├─ al2023   (10.10.1.23)         │
                            │  ├─ fedora   (10.10.1.41)         │
                            │  ├─ rocky8   (10.10.1.8)          │
                            │  ├─ rocky9   (10.10.1.9)          │
                            │  ├─ ubuntu22 (10.10.1.22)         │
                            │  └─ ubuntu24 (10.10.1.24)         │
                            └───────────────────────────────────┘
```

---

## 📁 디렉터리 구성

| 파일 | 설명 |
|---|---|
| [`main.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/main.tf) | VPC, 서브넷, 인터넷 게이트웨이, 보안그룹, 키페어 정의 |
| [`admin.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/admin.tf) | Admin (Ansible 컨트롤 노드) EC2 인스턴스 및 bootstrap 스크립트 |
| [`targets.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/targets.tf) | 6종 OS 테스트 인스턴스(AL2023, Fedora, Rocky 8/9, Ubuntu 22/24) 정의 |
| [`amis.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/amis.tf) | 각 OS별 최신 공식 AWS AMI 탐색 데이터 소스 |
| [`inventory.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/inventory.tf) | Ansible 인벤토리 자동 생성 (`inventory/aws_ec2.ini`, `inventory_admin.ini`) |
| [`variables.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/variables.tf) | AWS 리전, 인스턴스 타입, SSH 키 경로 등 변수 정의 |
| [`outputs.tf`](file:///home/keikun/project/kisa-linux-hardening/terraform/outputs.tf) | 인스턴스 IP 목록 및 SSH 접속 명령어 출력 |
| [`deploy.sh`](file:///home/keikun/project/kisa-linux-hardening/terraform/deploy.sh) | Terraform 초기화 및 인프라 원클릭 배포 스크립트 |
| [`sync_to_admin.sh`](file:///home/keikun/project/kisa-linux-hardening/terraform/sync_to_admin.sh) | 로컬 프로젝트 코드를 Admin 노드로 rsync 및 SSH 키 배포 |
| [`test.sh`](file:///home/keikun/project/kisa-linux-hardening/terraform/test.sh) | AWS 타깃 노드 대상 KISA 감사/적용 테스트 실행기 |
| [`destroy.sh`](file:///home/keikun/project/kisa-linux-hardening/terraform/destroy.sh) | AWS 테스트 인프라 완전 삭제 스크립트 |

---

## 🚀 빠른 시작 가이드

### 1. 사전 요구사항
- AWS CLI 인증 완료 (`aws sts get-caller-identity` 확인)
- Terraform 설치 (`>= 1.3.0`)
- SSH 키 생성 (`~/.ssh/id_ed25519` 또는 `id_rsa`)

### 2. 인프라 배포
```bash
# 원클릭 배포 (terraform init && apply)
bash terraform/deploy.sh
```

배포 완료 시 Ansible 인벤토리가 자동 생성됩니다:
- `inventory/aws_ec2.ini` : 로컬 호스트에서 타깃 Public IP로 직접 접근
- `terraform/inventory_admin.ini` : Admin 노드에서 타깃 Private IP로 내부 접근

---

## 🧪 테스트 실행 방식 (2가지 모드)

### 방식 A. Admin 노드 내부에서 테스트 (권장 클라우드 환경)

1. **프로젝트 코드 및 키 동기화:**
   ```bash
   bash terraform/sync_to_admin.sh
   ```

2. **Admin 노드 SSH 접속:**
   ```bash
   ssh -i ~/.ssh/id_ed25519 ubuntu@<ADMIN_PUBLIC_IP>
   ```

3. **Admin 노드에서 KISA 전수 감사 / 적용:**
   ```bash
   cd ~/kisa-linux-hardening

   # 전체 노드 전수 감사
   bash scripts/audit.sh

   # 특정 OS만 감사
   DISTRO=al2023 bash scripts/audit.sh
   DISTRO=rocky9 bash scripts/audit.sh

   # 실제 하드닝 적용
   ansible-playbook -i inventory/ec2.ini plays/site.yml --diff
   ```

---

### 방식 B. 로컬 호스트에서 AWS 노드로 직접 테스트

```bash
# 전체 AWS 인스턴스 전수 감사
bash terraform/test.sh

# 특정 OS만 감사 (예: Fedora, Ubuntu 24.04)
bash terraform/test.sh fedora
bash terraform/test.sh ubuntu24

# 특정 OS에 실제 보안 조치 적용
ACTION=apply bash terraform/test.sh rocky8
```

---

## 🧹 리소스 정리 (비용 방지)

테스트가 완료되면 생성된 AWS 리소스를 완전히 삭제합니다:

```bash
bash terraform/destroy.sh
```
