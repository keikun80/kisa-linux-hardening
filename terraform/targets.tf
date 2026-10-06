# ==============================================================================
# Target OS Test Nodes EC2 Instances (6 Distros)
# ==============================================================================

# 1. Amazon Linux 2023
resource "aws_instance" "al2023" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.targets.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  private_ip                  = "10.10.1.23"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "${var.project_name}-target-al2023"
    Role   = "target"
    Distro = "al2023"
  }
}

# 2. Fedora 41
resource "aws_instance" "fedora" {
  ami                         = data.aws_ami.fedora.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.targets.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  private_ip                  = "10.10.1.41"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "${var.project_name}-target-fedora"
    Role   = "target"
    Distro = "fedora"
  }
}

# 3. Rocky Linux 8
resource "aws_instance" "rocky8" {
  ami                         = data.aws_ami.rocky8.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.targets.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  private_ip                  = "10.10.1.8"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "${var.project_name}-target-rocky8"
    Role   = "target"
    Distro = "rocky8"
  }
}

# 4. Rocky Linux 9
resource "aws_instance" "rocky9" {
  ami                         = data.aws_ami.rocky9.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.targets.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  private_ip                  = "10.10.1.9"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "${var.project_name}-target-rocky9"
    Role   = "target"
    Distro = "rocky9"
  }
}

# 5. Ubuntu 22.04 LTS
resource "aws_instance" "ubuntu22" {
  ami                         = data.aws_ami.ubuntu22.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.targets.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  private_ip                  = "10.10.1.22"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "${var.project_name}-target-ubuntu22"
    Role   = "target"
    Distro = "ubuntu22"
  }
}

# 6. Ubuntu 24.04 LTS
resource "aws_instance" "ubuntu24" {
  ami                         = data.aws_ami.ubuntu24.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.targets.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true
  private_ip                  = "10.10.1.24"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "${var.project_name}-target-ubuntu24"
    Role   = "target"
    Distro = "ubuntu24"
  }
}
