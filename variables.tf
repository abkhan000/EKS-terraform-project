
variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  default     = "karpenter-demo"
}

variable "node_group_instance_type" {
  description = "Instance type for the node group"
  default     = "t3.medium"
}
