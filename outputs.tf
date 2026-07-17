# outputs.tf

# ------------------------------------------------------------------------------
# VPC Outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "El ID de la VPC creada."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "El bloque CIDR principal de la VPC."
  value       = aws_vpc.this.cidr_block
}

# ------------------------------------------------------------------------------
# Subnet Outputs
# ------------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "Lista con los IDs de las subredes públicas creadas."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Lista con los IDs de las subredes privadas creadas."
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Lista con los IDs de las subredes de bases de datos creadas."
  value       = aws_subnet.database[*].id
}

# ------------------------------------------------------------------------------
# NAT Gateway e Internet Gateway Outputs (Útiles para monitoreo o auditorías de red)
# ------------------------------------------------------------------------------
output "internet_gateway_id" {
  description = "El ID del Internet Gateway de la VPC."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_public_ips" {
  description = "Lista de las IPs públicas estáticas (Elastic IPs) asociadas a los NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}