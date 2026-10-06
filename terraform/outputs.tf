# ==============================================================================
# Terraform Outputs - IP Summary & SSH Guides
# ==============================================================================

output "admin_node" {
  description = "Admin (컨트롤 노드) 정보"
  value = {
    name       = "${var.project_name}-admin"
    public_ip  = aws_instance.admin.public_ip
    private_ip = aws_instance.admin.private_ip
    ssh_user   = "ubuntu"
    ssh_cmd    = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.admin.public_ip}"
  }
}

output "target_nodes" {
  description = "타깃 OS 테스트 노드 6종 목록"
  value = {
    al2023 = {
      name       = "${var.project_name}-target-al2023"
      public_ip  = aws_instance.al2023.public_ip
      private_ip = aws_instance.al2023.private_ip
      ssh_user   = "ec2-user"
      ssh_cmd    = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.al2023.public_ip}"
    }
    fedora = {
      name       = "${var.project_name}-target-fedora"
      public_ip  = aws_instance.fedora.public_ip
      private_ip = aws_instance.fedora.private_ip
      ssh_user   = "fedora"
      ssh_cmd    = "ssh -i ${var.private_key_path} fedora@${aws_instance.fedora.public_ip}"
    }
    rocky8 = {
      name       = "${var.project_name}-target-rocky8"
      public_ip  = aws_instance.rocky8.public_ip
      private_ip = aws_instance.rocky8.private_ip
      ssh_user   = "rocky"
      ssh_cmd    = "ssh -i ${var.private_key_path} rocky@${aws_instance.rocky8.public_ip}"
    }
    rocky9 = {
      name       = "${var.project_name}-target-rocky9"
      public_ip  = aws_instance.rocky9.public_ip
      private_ip = aws_instance.rocky9.private_ip
      ssh_user   = "rocky"
      ssh_cmd    = "ssh -i ${var.private_key_path} rocky@${aws_instance.rocky9.public_ip}"
    }
    ubuntu22 = {
      name       = "${var.project_name}-target-ubuntu22"
      public_ip  = aws_instance.ubuntu22.public_ip
      private_ip = aws_instance.ubuntu22.private_ip
      ssh_user   = "ubuntu"
      ssh_cmd    = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.ubuntu22.public_ip}"
    }
    ubuntu24 = {
      name       = "${var.project_name}-target-ubuntu24"
      public_ip  = aws_instance.ubuntu24.public_ip
      private_ip = aws_instance.ubuntu24.private_ip
      ssh_user   = "ubuntu"
      ssh_cmd    = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.ubuntu24.public_ip}"
    }
  }
}

output "quick_start_instructions" {
  description = "빠른 시작 가이드"
  value       = <<-EOT
    ========================================================================
    [1] Admin 노드로 프로젝트 코드 동기화 및 접속:
        bash terraform/sync_to_admin.sh
        ssh -i ${var.private_key_path} ubuntu@${aws_instance.admin.public_ip}

    [2] Admin 노드 내부에서 타깃 대상 KISA 전수 감사:
        cd ~/kisa-linux-hardening
        bash scripts/audit.sh

    [3] 로컬 호스트에서 타깃 대상 직접 KISA 감사:
        INV=inventory/aws_ec2.ini bash scripts/audit.sh
    ========================================================================
  EOT
}
