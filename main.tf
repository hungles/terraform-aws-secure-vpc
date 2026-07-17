# main.tf

# ------------------------------------------------------------------------------
# VPC Principal
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name        = "vpc-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Internet Gateway (IGW) para tráfico público
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "igw-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}