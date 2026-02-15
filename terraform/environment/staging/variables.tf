variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type = string
  default = "us-east-1"
}

variable "instance_type" {
  description = "The type of instance to launch"
  type = string
  default = "t3.micro"
}

variable "project_name" {
  description = "The name of the project"
  type = string
  default = "devblog"
}

variable "environment" {
  description = "The environment to deploy the resources"
  type = string
  default = "staging"
}