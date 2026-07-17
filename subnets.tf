# subnets.tf

# ------------------------------------------------------------------------------
# Subredes Públicas (Para Balanceadores de Carga y NAT Gateways)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones))

  # Asigna automáticamente una IP pública a los recursos aquí desplegados
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "subnet-${var.environment}-public-${element(var.availability_zones, count.index % length(var.availability_zones))}"
      Type        = "Public"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Subredes Privadas (Para Cómputo: EC2, ECS, EKS)
# ------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones))

  map_public_ip_on_launch = false

  tags = merge(
    {
      Name        = "subnet-${var.environment}-private-${element(var.availability_zones, count.index % length(var.availability_zones))}"
      Type        = "Private"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Subredes de Datos (Aisladas para bases de datos como RDS)
# ------------------------------------------------------------------------------
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones))

  map_public_ip_on_launch = false

  tags = merge(
    {
      Name        = "subnet-${var.environment}-db-${element(var.availability_zones, count.index % length(var.availability_zones))}"
      Type        = "Database"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}