data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.small"

  tags = {
    Name = "Main Server"
  }

  key_name = "Deployer"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  user_data = <<-EOL
    #!/bin/bash -xe

    echo "Installing dependencies"
    apt-get update -yqq
    apt-get install -yqq build-essential unzip

    echo "Installing Node.js with N"
    su ubuntu -c "curl -L https://bit.ly/n-install | N_PREFIX=/home/ubuntu/.n bash -s -- -y"

    echo "Installing Bun"
    su ubuntu -c "curl -fsSL https://bun.sh/install | bash"
  EOL
}

output "instance_ip" {
  description = "The public IP for ssh access"
  value       = aws_instance.server.public_ip
}
