# ==============================================================================
# Terraform & AWS Provider Configuration
# ==============================================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# 1. Query Existing Default VPC (Do NOT create custom VPC/Subnet/IGW)
# ==============================================================================

data "aws_vpc" "default" {
  default = true
}

# ==============================================================================
# 2. Ubuntu 20.04 LTS AMI Data Source (Technical Requirement)
# ==============================================================================

data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical Official Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==============================================================================
# 3. Security Group in Default VPC (HTTP Port 80 + SSH Port 22)
# ==============================================================================

resource "aws_security_group" "nginx_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Nginx web server allowing HTTP (80) and SSH (22)"
  vpc_id      = data.aws_vpc.default.id

  # Inbound HTTP (Port 80)
  ingress {
    description = "Allow inbound HTTP access from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH (Port 22)
  ingress {
    description = "Allow inbound SSH administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound All Traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    ManagedBy   = "Terraform"
  }
}

# ==============================================================================
# 4. EC2 Instance Provisioning (t2.micro Ubuntu 20.04 in Default VPC)
# ==============================================================================

resource "aws_instance" "nginx_server" {
  ami                         = data.aws_ami.ubuntu_20_04.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.nginx_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  # user_data script to install Nginx and configure custom index.html
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 1. Update package index and install Nginx
              apt-get update -y
              apt-get install -y nginx

              # 2. Start and enable Nginx service
              systemctl start nginx
              systemctl enable nginx

              # 3. Replace default index.html with custom HTML content
              cat << 'HTML' > /var/www/html/index.html
              <!DOCTYPE html>
              <html lang="en">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Terraform Nginx Server</title>
                  <style>
                      body {
                          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                          background-color: #f0f2f5;
                          display: flex;
                          justify-content: center;
                          align-items: center;
                          height: 100vh;
                          margin: 0;
                      }
                      .card {
                          background: #ffffff;
                          padding: 40px 50px;
                          border-radius: 12px;
                          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                          text-align: center;
                          max-width: 650px;
                      }
                      h1 {
                          color: #0366d6;
                          font-size: 24px;
                          line-height: 1.4;
                          margin-bottom: 16px;
                      }
                      p {
                          color: #586069;
                          font-size: 16px;
                          margin-bottom: 24px;
                      }
                      .badge {
                          display: inline-block;
                          background-color: #28a745;
                          color: #ffffff;
                          padding: 8px 20px;
                          border-radius: 20px;
                          font-size: 14px;
                          font-weight: 600;
                          letter-spacing: 0.5px;
                      }
                  </style>
              </head>
              <body>
                  <div class="card">
                      <h1>Welcome to the Terraform-managed Nginx Server on Ubuntu</h1>
                      <p>Provisioned automatically using <strong>Terraform</strong> on AWS EC2 (Ubuntu 20.04 LTS).</p>
                      <div class="badge">&#10004; Nginx Web Server Active</div>
                  </div>
              </body>
              </html>
              HTML

              # Ensure default debian fallback page is also updated
              cp /var/www/html/index.html /var/www/html/index.nginx-debian.html || true

              # 4. Restart Nginx to apply changes
              systemctl restart nginx
              EOF

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "HeroVired-DevOps-SkillTest-3-Reattempt"
  }
}
