#AWS provider
provider "aws" {
  region     = "ap-south-1"
  profile    = "mytest"
}

#tls private key
resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}	

#local file
resource "local_file" "key_name" {
  depends_on      = [tls_private_key.tls_key]
  content         = tls_private_key.tls_key.private_key_pem
  filename        = "tls_key.pem"
}

#aws key pair
resource "aws_key_pair" "tls_key" {
  depends_on      = [local_file.key_name]
  key_name        = "tls_key"
  public_key      = tls_private_key.tls_key.public_key_openssh
}

#security group
resource "aws_security_group" "ssh-http-1" {
  depends_on  = [aws_key_pair.tls_key]
  name        = "ssh-http"
  description = "allow ssh and http"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
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
   Name = "sg2"
 }
}
