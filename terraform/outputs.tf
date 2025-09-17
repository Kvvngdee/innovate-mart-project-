# outputs.tf: Outputs for the Terraform configuration

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster."
  value       = aws_eks_cluster.innovatemart_eks.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.innovatemart_eks.arn
}

output "kubeconfig_command" {
  description = "The command to update your kubeconfig file."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}
