# output "cluster_id" {
#   description = "EKS cluster ID"
#   value       = aws_eks_cluster.main.id
# }

# output "cluster_endpoint" {
#   description = "EKS cluster endpoint"
#   value       = aws_eks_cluster.main.endpoint
# }

# output "cluster_oidc_issuer_url" {
#   description = "OIDC issuer URL for IRSA"
#   value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
# }

# output "cluster_security_group_id" {
#   description = "Security group for cluster"
#   value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
# }