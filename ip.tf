variable "ip"{}
resource "null_resource" "r" {

connection {
type     = "ssh"
    user     = "ec2-user"
    private_key = file("/terraform_1/task1/static_obj/deployer-key")
    host     = var.ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv -r ~/*.html /var/www/html/"
      ]
}
}


