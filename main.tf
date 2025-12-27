############################################
# Provider
############################################
provider "aws" {
  region = "us-east-1"
}

############################################
# VPC
############################################
resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "trend-vpc"
  }
}

############################################
# Public Subnet
############################################
resource "aws_subnet" "trend_public_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "trend-public-subnet"
  }
}

############################################
# Internet Gateway
############################################
resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id

  tags = {
    Name = "trend-igw"
  }
}

############################################
# Route Table
############################################
resource "aws_route_table" "trend_public_rt" {
  vpc_id = aws_vpc.trend_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trend_igw.id
  }

  tags = {
    Name = "trend-public-rt"
  }
}

resource "aws_route_table_association" "trend_rt_assoc" {
  subnet_id      = aws_subnet.trend_public_subnet.id
  route_table_id = aws_route_table.trend_public_rt.id
}

############################################
# Security Group
############################################
resource "aws_security_group" "trend_sg" {
  name        = "trend-sg"
  description = "Allow SSH, Jenkins, NodePort"
  vpc_id      = aws_vpc.trend_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort Apps"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "trend-sg"
  }
}

############################################
# IAM Role (Minimal)
############################################
resource "aws_iam_role" "trend_ec2_role" {
  name = "trend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "trend_profile" {
  name = "trend-instance-profile"
  role = aws_iam_role.trend_ec2_role.name
}

############################################
# EC2 Instance (Jenkins + Docker + k3s)
############################################
resource "aws_instance" "trend_server" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.trend_public_subnet.id
  vpc_security_group_ids = [aws_security_group.trend_sg.id]
  key_name               = "brain-task-app"
  iam_instance_profile   = aws_iam_instance_profile.trend_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Java
              amazon-linux-extras install java-openjdk11 -y

              # Install Jenkins
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              yum install jenkins -y
              systemctl start jenkins
              systemctl enable jenkins
              usermod -aG docker jenkins

              # Install k3s (Lightweight Kubernetes)
              curl -sfL https://get.k3s.io | sh -

              EOF

  tags = {
    Name = "trend-free-tier-server"
  }
}

############################################
# Outputs
############################################
output "server_public_ip" {
  value = aws_instance.trend_server.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.trend_server.public_ip}:8080"
}
