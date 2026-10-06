# ==============================================================================
# Admin Node (Ansible Control Node) EC2 Instance
# ==============================================================================

resource "aws_instance" "admin" {
  ami                         = data.aws_ami.admin_ubuntu.id
  instance_type               = var.admin_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.admin.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive

    # 시스템 업데이트 및 기본 도구 설치
    apt-get update -y
    apt-get install -y software-properties-common curl wget git rsync tree python3-pip python3-venv

    # Ansible 설치
    apt-add-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible

    # 작업 디렉터리 생성
    mkdir -p /home/ubuntu/kisa-linux-hardening /home/ubuntu/.ssh
    chown -R ubuntu:ubuntu /home/ubuntu/kisa-linux-hardening /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh

    # Admin 노드용 기본 ansible.cfg 세팅
    cat <<'ANSCFG' > /home/ubuntu/ansible.cfg
    [defaults]
    host_key_checking = False
    retry_files_enabled = False
    stdout_callback = yaml
    timeout = 30
    ANSCFG
    chown ubuntu:ubuntu /home/ubuntu/ansible.cfg

    echo "Admin node initialization complete." > /var/log/admin_bootstrap.log
  EOF

  tags = {
    Name = "${var.project_name}-admin"
    Role = "admin"
  }
}
