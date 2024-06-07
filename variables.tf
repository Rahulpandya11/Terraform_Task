variable "region" {
  default = "us-east-1"
}

variable "ami" {
  default = "ami-03c983f9003cb9cd1" 
}

variable "instance_type" {
  default = "t2.micro"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "allowed_ip" {
  default     = "59.184.156.139/32"  
}
