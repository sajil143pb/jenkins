module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"
}


resource "tls_private_key" "this" {
   algorithm = "ED25519"
 }

 resource "aws_key_pair" "this" {
  key_name   = "terraform-ssh-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_sensitive_file" "this" {
  content  = tls_private_key.this.private_key_openssh
  filename = "${path.module}/sshkey-${aws_key_pair.this.key_name}"
}
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "Jenkins"
  instance_type          = "t2.medium"
  ami                    = "ami-04b4f1a9cf54c11d0"
  key_name               = aws_key_pair.this.key_name
  monitoring             = true
  associate_public_ip_address = "true"
  user_data = base64encode(<<EOF
    #!/bin/bash
    sudo apt update
    sudo apt install openjdk-17-jre-headless -y
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins -y
    sudo apt update
    sudo apt install docker.io -y
    sudo usermod -aG docker jenkins
    sudo usermod -aG docker ubuntu
    sudo systemctl restart docker
    EOF
)

  depends_on = [ aws_key_pair.this ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}