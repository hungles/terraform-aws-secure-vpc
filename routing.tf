# routing.tf

# ==============================================================================
# 1. TABLAS DE RUTEO
# ==============================================================================

# ------------------------------------------------------------------------------
# Tabla de Ruteo Pública
# ------------------------------------------------------------------------------
# Todas las subredes públicas comparten una única tabla de ruteo que envía todo el 
# tráfico externo (0.0.0.0/0) directamente al Internet Gateway (IGW).
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name        = "rt-${var.environment}-public"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Tablas de Ruteo Privadas
# ------------------------------------------------------------------------------
# Para la infraestructura privada, creamos tantas tablas de ruteo como subredes privadas tengamos.
# Cada tabla de ruteo privada enviará el tráfico de salida al NAT Gateway adecuado:
# - Si es "single NAT", todas las tablas apuntarán al primer (y único) NAT Gateway.
# - De lo contrario, cada tabla se mapeará uno a uno con el NAT de su propia zona de disponibilidad.
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    {
      Name        = "rt-${var.environment}-private-${element(var.availability_zones, count.index)}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Tabla de Ruteo de Datos (Totalmente Aislada)
# ------------------------------------------------------------------------------
# Las buenas prácticas de seguridad de AWS (y el marco Well-Architected) sugieren que las 
# bases de datos no tengan rutas por defecto hacia el exterior (ni siquiera NAT Gateway).
# Por lo tanto, esta tabla solo permite tráfico interno dentro de la VPC.
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "rt-${var.environment}-database"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}


# ==============================================================================
# 2. ASOCIACIONES DE TABLAS DE RUTEO
# ==============================================================================

# ------------------------------------------------------------------------------
# Asociación Pública
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# Asociación Privada
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ------------------------------------------------------------------------------
# Asociación de Base de Datos
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}