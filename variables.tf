variable "environment" {
  type        = string
  description = "Nombre del entorno (ej. dev, qa, prod)."
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod", "prd"], var.environment)
    error_message = "El entorno debe ser uno de los siguientes: dev, prd, prod."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "El bloque CIDR principal para la VPC."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "El bloque vpc_cidr debe tener un formato CIDR válido (ej. 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Lista de zonas de disponibilidad en las que se desplegarán las subredes (mínimo 2 recomendado)."
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las subredes públicas (una por AZ)."
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las subredes privadas de aplicación (una por AZ)."
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las subredes privadas de bases de datos (una por AZ)."
  default     = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_single_nat_gateway" {
  type        = bool
  description = "Si es true, se creará un solo NAT Gateway compartido para ahorrar costos en entornos que no sean de producción."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags adicionales para asociar a todos los recursos de la red."
  default     = {}
}