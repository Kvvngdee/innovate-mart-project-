# variables.tf: Input variables for the Terraform configuration

variable "region" {
  type    = string
  default = "eu-west-1"
  description = "The AWS region to deploy the infrastructure."
}

variable "cluster_name" {
  type    = string
  default = "innovatemart-eks-cluster"
  description = "The name of the EKS cluster."
}
