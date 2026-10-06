# ==============================================================================
# Ansible Inventory Auto-Generation (Admin Node & Local Node)
# ==============================================================================

# 1. Admin 노드 내부용 인벤토리 (Private IP 기준)
resource "local_file" "inventory_admin" {
  content = <<-EOF
# =============================================================================
# KISA Linux Hardening - AWS Internal Inventory (For Admin Node)
# Generated automatically by Terraform
# =============================================================================

[al2023]
kisa-aws-al2023 ansible_host=${aws_instance.al2023.private_ip}

[al2023:vars]
ansible_user=ec2-user

[fedora]
kisa-aws-fedora ansible_host=${aws_instance.fedora.private_ip}

[fedora:vars]
ansible_user=fedora

[rocky8]
kisa-aws-rocky8 ansible_host=${aws_instance.rocky8.private_ip}

[rocky8:vars]
ansible_user=rocky

[rocky9]
kisa-aws-rocky9 ansible_host=${aws_instance.rocky9.private_ip}

[rocky9:vars]
ansible_user=rocky

[ubuntu22]
kisa-aws-ubuntu22 ansible_host=${aws_instance.ubuntu22.private_ip}

[ubuntu22:vars]
ansible_user=ubuntu

[ubuntu24]
kisa-aws-ubuntu24 ansible_host=${aws_instance.ubuntu24.private_ip}

[ubuntu24:vars]
ansible_user=ubuntu

[all:children]
al2023
fedora
rocky8
rocky9
ubuntu22
ubuntu24

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes'
EOF

  filename = "${path.module}/inventory_admin.ini"
}

# 2. 로컬 호스트용 인벤토리 (Public IP 기준 - inventory/aws_ec2.ini)
resource "local_file" "inventory_public" {
  content = <<-EOF
# =============================================================================
# KISA Linux Hardening - AWS Public IP Inventory (For Direct Local Access)
# Generated automatically by Terraform
# =============================================================================

[admin]
kisa-aws-admin ansible_host=${aws_instance.admin.public_ip}

[admin:vars]
ansible_user=ubuntu

[al2023]
kisa-aws-al2023 ansible_host=${aws_instance.al2023.public_ip}

[al2023:vars]
ansible_user=ec2-user

[fedora]
kisa-aws-fedora ansible_host=${aws_instance.fedora.public_ip}

[fedora:vars]
ansible_user=fedora

[rocky8]
kisa-aws-rocky8 ansible_host=${aws_instance.rocky8.public_ip}

[rocky8:vars]
ansible_user=rocky

[rocky9]
kisa-aws-rocky9 ansible_host=${aws_instance.rocky9.public_ip}

[rocky9:vars]
ansible_user=rocky

[ubuntu22]
kisa-aws-ubuntu22 ansible_host=${aws_instance.ubuntu22.public_ip}

[ubuntu22:vars]
ansible_user=ubuntu

[ubuntu24]
kisa-aws-ubuntu24 ansible_host=${aws_instance.ubuntu24.public_ip}

[ubuntu24:vars]
ansible_user=ubuntu

[all:children]
al2023
fedora
rocky8
rocky9
ubuntu22
ubuntu24

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=${var.private_key_path}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes'
EOF

  filename = "${path.module}/../inventory/aws_ec2.ini"
}
