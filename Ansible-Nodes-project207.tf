provider "aws" {
  region = "us-east-1"
  //  access_key = ""
  //  secret_key = ""
  //  If you have entered your credentials in AWS CLI before, you do not need to use these arguments.
}

data "aws_ami" "tf-ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_iam_role" "ansible-access-role" {
  name = "awsrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : "ec2:*",
            "Effect" : "Allow",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : "elasticloadbalancing:*",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : "cloudwatch:*",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : "autoscaling:*",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : "iam:CreateServiceLinkedRole",
            "Resource" : "*",
            "Condition" : {
              "StringEquals" : {
                "iam:AWSServiceName" : [
                  "autoscaling.amazonaws.com",
                  "ec2scheduled.amazonaws.com",
                  "elasticloadbalancing.amazonaws.com",
                  "spot.amazonaws.com",
                  "spotfleet.amazonaws.com",
                  "transitgateway.amazonaws.com"
                ]
              }
            }
          }
        ]
      }
    )
  }
  tags = {
    Name = "AWS Role for Ansible"
  }
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ansible-profile"
  role = aws_iam_role.ansible-access-role.name
}

resource "aws_security_group" "ansible-sec-gr-manager" {
  name = "ansible-sec-gr-manager"
  tags = {
    Name = "ansible-manager-sec-group"
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ansible-sec-gr-dbase" {
  name = "ansible-sec-gr-dbase"
  tags = {
    Name = "ansible-dbase-sec-group"
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ansible-sec-gr-nodejs" {
  name = "ansible-sec-gr-nodejs"
  tags = {
    Name = "ansible-nodejs-sec-group"
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ansible-sec-gr-react" {
  name = "ansible-sec-gr-react"
  tags = {
    Name = "ansible-react-sec-group"
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "sg-rule-dbase" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.ansible-sec-gr-dbase.id
  source_security_group_id = aws_security_group.ansible-sec-gr-nodejs.id
}

resource "aws_instance" "ansible-dbase" {
  ami             = data.aws_ami.tf-ami.id
  instance_type   = "t2.micro"
  key_name        = "ec2_key"
  security_groups = ["ansible-sec-gr-dbase"]
  tags = {
    Name = "Ansible-Node1-dbase"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              hostnamectl set-hostname "node-dbase"
              bash
              EOF
}

resource "aws_instance" "ansible-nodejs" {
  ami             = data.aws_ami.tf-ami.id
  instance_type   = "t2.micro"
  key_name        = "ec2_key"
  security_groups = ["ansible-sec-gr-nodejs"]
  tags = {
    Name = "Ansible-Node2-nodejs"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              hostnamectl set-hostname "node-Nodejs"
              bash
              EOF
}

resource "aws_instance" "ansible-react" {
  ami             = data.aws_ami.tf-ami.id
  instance_type   = "t2.micro"
  key_name        = "ec2_key"
  security_groups = ["ansible-sec-gr-react"]
  tags = {
    Name = "Ansible-Node3-React"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              hostnamectl set-hostname "node-React"
              bash
              EOF
}

resource "aws_instance" "ansible-manager" {
  ami                  = data.aws_ami.tf-ami.id
  instance_type        = "t2.micro"
  key_name             = "ec2_key"
  security_groups      = ["ansible-sec-gr-manager"]
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  tags = {
    Name = "Ansible-Manager"
  }

  provisioner "file" {
    source      = "/home/hakan/Masaüstü/ec2_key.txt"
    destination = "/home/ec2-user/ec2_key.txt"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/hakan/Masaüstü/ec2_key.txt")
      host        = aws_instance.ansible-manager.public_ip
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install ansible2
              hostnamectl set-hostname "ansible-manager"
              bash
              yum install python-boto3 python-botocore -y
              cat <<ec2_key> /home/ec2-user/inventory_aws_ec2.yml
              plugin: aws_ec2
              regions:
                - "us-east-1"
              keyed_groups:
                - key: tags.Name
              filters:
                instance-state-name : running
              compose:
                ansible_host: public_ip_address
              ec2_key
              cat <<ec2_key> /home/ec2-user/ansible.cfg
              [defaults]
              host_key_checking = False
              inventory=/home/ec2-user/inventory_aws_ec2.yml
              interpreter_python=auto_silent
              private_key_file=~/ec2_key.txt
              ec2_key
              chown ec2-user:ec2-user /home/ec2-user/*
              chmod 400 /home/ec2-user/ec2_key.txt
              EOF
}


output "control-public-ip" {
  value = aws_instance.ansible-manager.public_ip
}
output "control-private-ip" {
  value = aws_instance.ansible-manager.private_ip
}
output "worker-dbase-ip" {
  value = aws_instance.ansible-dbase.private_ip
}
output "worker-nodejs-ip" {
  value = aws_instance.ansible-nodejs.private_ip
}
output "worker-react-ip" {
  value = aws_instance.ansible-react.private_ip
}
