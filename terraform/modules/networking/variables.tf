variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "The CIDR block for the public subnet"
  type = string
  default = "10.0.1.0/24"
}

variable "public_route_table_cidr_block_0" {
  description = "The CIDR block for the public route table"
  type = string
  default = "0.0.0.0/0"
}

variable "project_name" {
  description = "The name of the project to deploy the networking resources"
  type = string
}

variable "environment" {
  description = "The environment to deploy the networking resources"
  type = string
}

variable "map_public_ip_on_launch" {
  description = "Whether to map a public IP address to the instances launched in the subnet"
  type = bool
  default = true
}