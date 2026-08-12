variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3" 

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region identifier (e.g., eu-west-3)."
  }
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Valeur de l'instance aws nom de tag."
  type        = string
  default     = "dev-instance"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "eu-west-3a"
}

variable "aws_ami" {
  description = "The AMI ID to use for the EC2 instance Debian 13"
  type        = string
  default     = "ami-03dbc12aeff16b2d4"
}

variable "map_public_ip_on_launch" {
  description = "Whether to assign a public IP address to instances launched in the subnet"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to access the instance via SSH"
  type        = string
  default     = "0.0.0.0/0"
}
