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
  user_data = file("userdata.sh")

  depends_on = [ aws_key_pair.this ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}