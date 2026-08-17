module "network" {
  source                  = "../../modules/network"
  vpc_cidr_block          = var.vpc_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

module "security" {
  source           = "../../modules/security"
  environment      = var.environment
  ssh_allowed_cidr = var.ssh_allowed_cidr
  vpc_id           = module.network.vpc_id
}

module "compute" {
  source            = "../../modules/compute"
  ami_id            = var.aws_ami
  instance_type     = var.instance_type
  environment       = var.environment
  subnet_id         = module.network.subnet_id
  security_group_id = module.security.security_group_id
  hostname          = var.hostname
  username          = var.username
  ssh_public_key    = file(var.ssh_public_key_path)
}

