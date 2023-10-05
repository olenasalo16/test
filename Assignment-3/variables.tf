# Define variable for ingress ports
variable "ingress_ports" {
  type    = list(number)
  default = [80, 443, 22]
}
############################
variable "ami_id" { 
type = string
}
##############################
variable "ec2_type" { 
type = string
}
#########################
variable "ssh_key_name" { 
type = string
}
#############################
variable "vpc_cidr_block" { 
type = string
}

#############################
variable "public_subnet_a_cidr_block" { 
type = string
}
#############################
variable "public_subnet_b_cidr_block" { 
type = string
}
#############################
variable "public_subnet_c_cidr_block" { 
type = string
}
#############################
variable "private_subnet_a_cidr_block" { 
type = string
}
#############################
variable "private_subnet_b_cidr_block" { 
type = string
}
#############################
variable "private_subnet_c_cidr_block" { 
type = string
}
