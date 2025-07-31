variable "cidr" {
  description = "value for ip range in vpc"
  default = "10.0.0.0/16"
}

variable "cidr-sub1" {
  description = "value for ip range for subnet1"
  default = "10.0.0.0/24"
}

variable "cidr-sub2" {
  description = "value for ip range for subnet2"
  default = "10.0.1.0/24"
}

variable "ami" {
  description = "value of ami for instance"
  default = "ami-0f918f7e67a3323f0"
}

variable "instance-type" {
  description = "value for instance type"
  default = "t2.micro"
}