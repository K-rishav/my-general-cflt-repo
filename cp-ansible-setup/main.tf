terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"  # Replace with the desired version constraint
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "network" {
  source = "./network"
}

module "instances" {
  source = "./instances"
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.subnet_ids
  public_subnet_id = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  bastion_sg_id = module.network.bastion_sg_id
  private_sg_id = module.network.private_sg_id
}

# module "brokers" {
#   source = "./message_brokers"
#   subnet_ids = module.network.subnet_ids
#   sg_id = module.network.private_sg_id
# }

# module "eks" {
#   source = "./eks"
#   vpc_id = module.network.vpc_id
#   subnet_ids = module.network.subnet_ids
#   sg_id = module.network.private_sg_id
# }