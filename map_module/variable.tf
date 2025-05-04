variable "ec2_instance" {
    type = map(object({
        ami= string
      instance_type = string
      availability_zone= string 
    }))
  
}