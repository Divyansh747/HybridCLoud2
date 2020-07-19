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
