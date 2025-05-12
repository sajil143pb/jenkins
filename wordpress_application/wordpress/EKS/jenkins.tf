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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "jenkinsvpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  public_subnets  = ["10.0.101.0/24"]

  map_public_ip_on_launch = true


  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "jenkins_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins-sg"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = module.vpc.default_vpc_id
  ingress_cidr_blocks      = ["10.10.0.0/16"]
  ingress_rules            = ["https-443-tcp"]
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}



module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "Jenkins"
  instance_type          = "t2.medium"
  ami                    = "ami-04b4f1a9cf54c11d0"
  key_name               = aws_key_pair.this.key_name
  monitoring             = true
  associate_public_ip_address = "true"
  vpc_security_group_ids     = [module.jenkins_sg.security_group_id]
  user_data = data.template_file.jenkins_user_data.rendered
  depends_on = [ aws_key_pair.this, module.jenkins_sg, module.vpc ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "template_file" "jenkins_user_data" {
  template = file("${path.module}/userdata.sh")
}

output "userdata" { value = data.template_file.jenkins_user_data.rendered }