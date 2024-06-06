variable "region" {
  default = "us-west-2"
}

variable "ami" {
  default = "ami-0eb9d67c52f5c80e5"  # Replace with your desired AMI
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
  description = "The IP address allowed to SSH into the bastion host"
  default     = "59.184.156.139/32"  # Replace YOUR_IP with your IP address
}
