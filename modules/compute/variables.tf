variable "environment" { type = string }
variable "ami_id"      { type = string }
variable "instance_type" { type = string }
variable "subnet_id"         { type = string }
variable "security_group_id" { type = string }
variable "hostname" { type = string }
variable "username" { type = string }
variable "ssh_public_key" { type = string }