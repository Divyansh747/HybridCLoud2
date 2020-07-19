#AWS provider
provider "aws" {
  region     = "ap-south-1"
  profile    = "default"
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

#aws instance
resource "aws_instance" "aws-os-1" {
  depends_on = [aws_security_group.ssh-http-1]
  ami               = "ami-0447a12f28fddb066"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1a"
  security_groups   = ["ssh-http"]
  key_name          = aws_key_pair.tls_key.key_name
  user_data         = <<-EOF
                       #!/bin/bash
                       sudo yum install httpd -y
                       sudo yum install git wget -y
                       sudo systemctl start httpd
                       sudo systemctl enable httpd
                       EOF
  tags = {
    Name = "aws-os-1"
  }
}

#aws efs file system
resource "aws_efs_file_system" "test-efs" {
  depends_on     = [aws_instance.aws-os-1]
  creation_token = "test-efs"

  tags = {
    Name = "test-efs"
  }
}

#aws efs mount target
resource "aws_efs_mount_target" "alpha" {
  file_system_id  = "${aws_efs_file_system.test-efs.id}"
  subnet_id       = aws_instance.aws-os-1.subnet_id
  security_groups = ["${aws_security_group.ssh-http-1.id}"]
  depends_on      = [aws_efs_file_system.test-efs]
}

#null resource for installing packages in EC2 machine
resource "null_resource"  "mount-efs" {
  depends_on = [aws_efs_mount_target.alpha]
 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.tls_key.private_key_pem
    host        = aws_instance.aws-os-1.public_ip 
  }
  
  provisioner "remote-exec" {
    inline = [
      "yum install amazon-efs-utils nfs-utils -y",
      "sudo mount -t efs ${aws_efs_file_system.test-efs.id}:/ /var/www/html",
      "sudo echo '${aws_efs_file_system.test-efs.id}:/ /var/www/html efs defaults,_netdev 0 0' >> /etc/fstab",
      "sudo git clone https://github.com/Divyansh747/Terraform_AWS-task-2.git /var/www/html",
      "sudo chmod 777 /var/www/html/index.html"
    ] 
  }
}

#aws s3 bucket
resource "aws_s3_bucket" "aws-s3-test" {
  depends_on = [null_resource.mount-efs]
  bucket = "awstestbucket747"
  acl    = "public-read"
  force_destroy = true

  provisioner  "local-exec" {
    command = "wget https://github.com/Divyansh747/Terraform_AWS-task-2/blob/master/image-1.png"
  }
}

#aws s3 bucket object
resource "aws_s3_bucket_object" "object" {
  depends_on = [aws_s3_bucket.aws-s3-test]
  bucket = "awstestbucket747"
  key    = "image-1.png"
  source = "image-1.png"
}
	
#aws cloudfront with s3
resource "aws_cloudfront_distribution" "aws-cloudfront-s3" {
    depends_on = [aws_s3_bucket_object.object]
    origin {
        domain_name = "awstestbucket747.s3.amazonaws.com"
        origin_id = "S3-awstestbucket747"

        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
    enabled = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-awstestbucket747"

        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false

            cookies {
              forward = "none"
           }
       }


        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
 
provisioner "local-exec" {
     command = "echo ${self.domain_name}/${aws_s3_bucket_object.object.key} > cloudfront_link.txt"
}

provisioner "local-exec" {
     command = "echo ${aws_instance.aws-os-1.public_ip}  > ec2_link.txt"
}

}
