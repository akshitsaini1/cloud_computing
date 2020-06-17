provider "aws" {
region ="ap-south-1"
profile ="Akshit"
}
variable "fname"{}
variable "fpath"{}
resource "aws_s3_bucket_object" "object" {
	bucket= "akshit-test-bucket"
	key = var.fname
	source = var.fpath
	acl="public-read-write"
}
