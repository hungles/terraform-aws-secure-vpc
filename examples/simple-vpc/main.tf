# examples/simple-vpc/main.tf

# ------------------------------------------------------------------------------
# Configuración del Módulo de VPC Segura
# ------------------------------------------------------------------------------
module "vpc_dev" {
  # Apunta al código del módulo base que está dos niveles arriba
  source = "../../"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"

  # Para pruebas, usamos solo 2 zonas de disponibilidad
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Rangos de red distribuidos en las 2 AZs
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

  # Habilitamos un solo NAT Gateway para ahorrar costos en desarrollo
  enable_single_nat_gateway = true

  # Tags organizacionales
  tags = {
    Project   = "SecureInfrastructure"
    Owner     = "DevOpsTeam"
    CostCenter = "101-R&D"
  }
}