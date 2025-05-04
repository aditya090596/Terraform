
resource "aws_key_pair" "key-value" {
  key_name   = "terraform-key"
  public_key = file("/home/aditya_09/Terraform/AWS_Terrform/e2e-proj1/key.pub") # Reads the public key file
}

resource "awscc_ec2_instance" "example" {
  instance_type = var.instance_type
  image_id      = var.ami # Amazon Linux 2 AMI ID
  subnet_id     = var.subnet_id_value
  key_name      = aws_key_pair.key-value.key_name

  # iam_instance_profile = awscc_iam_instance_profile.example.instance_profile_name

  security_group_ids = var.security_group_id

  tags = [{
    key   = "Name"
    value = "example-instance"
    }, {
    key   = "Modified By"
    value = "AWSCC"
  }]

user_data = base64encode(<<-EOF
  #!/bin/bash
  dnf update -y
  dnf install -y httpd
  sleep 5  # Ensure package installation completes before starting service

  systemctl start httpd
  systemctl enable httpd

  mkdir -p /var/www/html/Images  # Ensure the directory exists before copying files
  chown -R ec2-user:ec2-user /var/www/html
  chmod -R 755 /var/www/html/Images
  chmod -R 755 /var/www/html # Set proper permissions
EOF
)
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 8
        volume_type           = "gp2"
        delete_on_termination = true
      }
    }
  ]

}
resource "null_resource" "setup_ec2_instance" {
  depends_on = [awscc_ec2_instance.example]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("/home/aditya_09/Terraform/AWS_Terrform/e2e-proj1/key.pem")
    host        = awscc_ec2_instance.example.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/www/html/Images",
      "sudo chown -R ec2-user:ec2-user /var/www/html"
    ]
  }

  provisioner "file" {
    source      = "/home/aditya_09/Terraform/AWS_Terrform/e2e-proj1/index2.html"
    destination = "/var/www/html/index2.html"
  }

  provisioner "file" {
    source      = "/home/aditya_09/Terraform/AWS_Terrform/e2e-proj1/Images/"
    destination = "/var/www/html/Images"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod -R 755 /var/www/html",
      "sudo systemctl restart httpd",
      "sudo mv /var/www/html/index2.html /var/www/html/index.html"
    ]
  }
}
