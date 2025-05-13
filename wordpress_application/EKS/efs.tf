resource "aws_efs_file_system" "wordpress" {
  creation_token = "wordpress"

  tags = {
    Name = "MyProduct"
  }
}