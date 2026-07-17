# nat.tf

# ------------------------------------------------------------------------------
# IPs Elásticas (EIP) para los NAT Gateways
# ------------------------------------------------------------------------------
# Necesitamos reservar direcciones IP públicas estáticas para asociarlas a nuestros NAT Gateways.
# El número de IPs elásticas que creamos depende de la estrategia de NAT:
# - Si se habilita "single NAT", solo creamos 1.
# - De lo contrario, creamos tantas como subredes públicas tengamos (uno por AZ).
resource "aws_eip" "nat" {
  count = var.enable_single_nat_gateway ? 1 : length(var.public_subnet_cidrs)

  domain = "vpc"

  tags = merge(
    {
      Name        = var.enable_single_nat_gateway ? "eip-${var.environment}-nat-single" : "eip-${var.environment}-nat-${element(var.availability_zones, count.index)}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  # Es una buena práctica indicar explícitamente que dependemos del Internet Gateway
  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# NAT Gateways
# ------------------------------------------------------------------------------
# El NAT Gateway permite que los recursos en subredes privadas inicien conexiones de salida
# hacia internet (ej. descargar actualizaciones, conectar con APIs externas), pero bloquea
# que internet inicie conexiones directamente hacia ellos.
resource "aws_nat_gateway" "this" {
  count = var.enable_single_nat_gateway ? 1 : length(var.public_subnet_cidrs)

  # El NAT Gateway siempre DEBE residir en una subred pública para tener salida a internet.
  # - Si es "single NAT", lo desplegamos siempre en la primera subred pública.
  # - De lo contrario, desplegamos uno en cada subred pública.
  subnet_id     = var.enable_single_nat_gateway ? aws_subnet.public[0].id : aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = merge(
    {
      Name        = var.enable_single_nat_gateway ? "nat-${var.environment}-single" : "nat-${var.environment}-${element(var.availability_zones, count.index)}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}