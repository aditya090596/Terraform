resource "aws_instance" "ec2" {
    for_each = var.ec2_instance
  ami                     = each.value.ami
  instance_type           = each.value.instance_type
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }

}