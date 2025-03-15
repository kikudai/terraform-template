provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./modules/network"

  vpc_cidr                 = var.vpc_cidr
  subnet_cidrs             = var.subnet_cidrs
  nat_network_interface_id = module.compute.nat_network_interface_id
  vpn_client_cidr         = var.vpn_client_cidr
  my_ip                   = var.my_ip
}

module "compute" {
  source = "./modules/compute"
  
  key_name                = "your-key-name"
  nat_ami                 = var.nat_ami
  public_subnet_id        = module.network.public_subnet_1a_id
  nat_security_group_id   = module.network.nat_sg_id
  
  windows_ami              = var.windows_ami
  private_subnet_id        = module.network.private_subnet_1a_id
  windows_security_group_id = module.network.windows_ad_sg_id
  iam_instance_profile     = module.iam.instance_profile_name
  
  userdata_template_path  = "${path.module}/userdata.ps1"
  install_adds           = var.install_adds
  domain_name           = var.domain_name
  domain_netbios_name   = var.domain_netbios_name
  domain_admin_password = var.domain_admin_password
}

module "iam" {
  source = "./modules/iam"
}

module "vpn" {
  source = "./modules/vpn"

  vpc_id = module.network.vpc_id

  # セキュリティグループ
  security_group_ids = [module.network.vpn_endpoint_sg_id]


  # Active Directory関連
  dns_servers = [module.compute.windows_ad_private_ip]

  domain_name          = var.domain_name

  # ネットワーク関連
  subnet_id_1            = module.network.public_subnet_1c_id
  subnet_id_2            = module.network.private_subnet_1a_id
  target_network_cidr    = module.network.vpc_cidr

  vpn_client_cidr  = var.vpn_client_cidr
}
