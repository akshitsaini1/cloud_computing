provider "aws" {
region ="ap-south-1"
profile ="saini"
}
resource "aws_security_group" "sec_grp" {
 name = "HTTP&SSH"
 ingress {
    description = "TLS from VPC"
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
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 }

 
 output "security_group"{
 value= aws_security_group.sec_grp.name
 }
 
 
resource "aws_key_pair" "key_pair" {
  key_name   = "deployer-key"
  public_key = file("/terraform_1/task1/resource_init/task1_key.pub.pub")
}


resource "aws_instance"  "webs" {
  ami           = "ami-07a8c73a650069cf3"
  instance_type = "t2.micro"
  key_name	= aws_key_pair.key_pair.key_name
  security_groups =  [ aws_security_group.sec_grp.name ] 
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/terraform_1/task1/resource_init/deployer-key")
    host     = aws_instance.webs.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      "sudo mkdir ~/webpages"
    ]
  }

  tags = {
    Name = "webs"
  }
}
resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.webs.availability_zone
  size              = 1
  tags = {
    Name = "webs"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs.id}"
  instance_id = "${aws_instance.webs.id}"
  force_detach = true
}
output "ebs"{
value=aws_ebs_volume.ebs.id
}


resource "null_resource" "mount"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/terraform_1/task1/resource_init/deployer-key")
    host     = aws_instance.webs.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
    ]
  }
}


resource "aws_s3_bucket" "s3b" {
  bucket = "akshit-test-bucket"
  acl    = "public-read-write"
  force_destroy=true
}



resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on=[aws_s3_bucket.s3b]
  origin {
    domain_name = aws_s3_bucket.s3b.bucket_regional_domain_name
    origin_id   = "custom-akshit-test-bucket"


  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"

 


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "custom-akshit-test-bucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
output "domain_name" {
 depends_on=[aws_s3_bucket.s3b]
 value= aws_cloudfront_distribution.s3_distribution.domain_name
}




