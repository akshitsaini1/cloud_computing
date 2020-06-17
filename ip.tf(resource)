resource "null_resource" "nulllocal4"{
	depends_on=[aws_instance.webs]
	provisioner "local-exec" {
		command="echo ${aws_instance.webs.public_ip} > /terraform_1/task1/ip.txt"
	}
}

resource "null_resource" "nulllocal5"{
	depends_on=[aws_s3_bucket.s3b]
	provisioner "local-exec" {
		command="echo ${aws_cloudfront_distribution.s3_distribution.domain_name} > /terraform_1/task1/domain_name.txt"
	}
}
