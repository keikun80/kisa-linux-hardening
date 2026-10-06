# ==============================================================================
# Terraform Variables - KISA Linux Hardening AWS Test Environment
# ==============================================================================

variable "aws_region" {
  description = "AWS 리전 (예: ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_profile" {
  description = "AWS CLI 프로파일 이름 (선택 사항, 미지정 시 default 또는 AWS_PROFILE 환경변수 사용)"
  type        = string
  default     = null
}

variable "project_name" {
  description = "프로젝트 식별 태그"
  type        = string
  default     = "kisa-linux-hardening"
}

variable "environment" {
  description = "배포 환경 (test, staging 등)"
  type        = string
  default     = "test"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "공용 서브넷 CIDR 블록"
  type        = string
  default     = "10.10.1.0/24"
}

variable "public_key_path" {
  description = "EC2 인스턴스에 주입할 호스트의 SSH 공개키 경로"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "private_key_path" {
  description = "Admin 노드에서 타깃 노드 접속에 사용할 SSH 개인키 경로"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "admin_instance_type" {
  description = "Admin (컨트롤 노드) EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "target_instance_type" {
  description = "타깃 테스트 EC2 인스턴스 타입"
  type        = string
  default     = "t3.small"
}

variable "allowed_ssh_cidr_blocks" {
  description = "호스트에서 Admin/Target 인스턴스로 SSH 접근을 허용할 IP 대역"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
