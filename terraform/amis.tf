# ==============================================================================
# AWS Official AMIs Data Source
# ==============================================================================

# 1. Admin Node: Ubuntu 24.04 LTS (Noble)
data "aws_ami" "admin_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Target: Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 3. Target: Fedora Cloud 41
data "aws_ami" "fedora" {
  most_recent = true
  owners      = ["125523088429"] # Fedora Cloud

  filter {
    name   = "name"
    values = ["Fedora-Cloud-Base-AmazonEC2.x86_64-41-*", "Fedora-Cloud-Base-*.x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 4. Target: Rocky Linux 8
data "aws_ami" "rocky8" {
  most_recent = true
  owners      = ["792107900819", "aws-marketplace"] # Rocky Enterprise Software Foundation

  filter {
    name   = "name"
    values = ["Rocky-8-EC2-Base-*.x86_64*", "Rocky-8-EC2-*.x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 5. Target: Rocky Linux 9
data "aws_ami" "rocky9" {
  most_recent = true
  owners      = ["792107900819", "aws-marketplace"] # Rocky Enterprise Software Foundation

  filter {
    name   = "name"
    values = ["Rocky-9-EC2-Base-*.x86_64*", "Rocky-9-EC2-*.x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 6. Target: Ubuntu 22.04 LTS (Jammy)
data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 7. Target: Ubuntu 24.04 LTS (Noble)
data "aws_ami" "ubuntu24" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
