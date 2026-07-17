# examples/simple-vpc/outputs.tf

output "example_vpc_id" {
  description = "ID de la VPC creada en el entorno de desarrollo."
  value       = module.vpc_dev.vpc_id
}

output "example_public_subnets" {
  description = "Subredes públicas de ejemplo."
  value       = module.vpc_dev.public_subnet_ids
}

output "example_private_subnets" {
  description = "Subredes privadas de ejemplo."
  value       = module.vpc_dev.private_subnet_ids
}

output "example_nat_ips" {
  description = "IPs de salida del NAT Gateway creado."
  value       = module.vpc_dev.nat_gateway_public_ips
}