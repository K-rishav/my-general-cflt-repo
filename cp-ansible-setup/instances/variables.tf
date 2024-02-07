variable "ami_id" {
  type    = string
  default = "ami-0a6e38961e6e621b0"
}

variable "instance_type" {
  type    = string
  default = "m5.large"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type    = list(string)
}

variable "instance_count" {
  type    = string
  default = "10"
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "private_sg_id" {
  type = string
}

# Define variables
variable "key_pair_name" {
  type = string
  default = "default-key"
}

variable "bastion_host_name" {
  type = string
  default = "cp-bastion"

}
variable "cp_host_name" {
  type = string
  default = "cp"
}