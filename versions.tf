# versions.tf

terraform {
  # Requerimos al menos Terraform 1.3.0 porque introduce validaciones de variables mejoradas
  # y mejoras significativas en el motor de renderizado de planes.
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0" # Bloqueamos a la version mayor v5 para aprovechar las últimas características de AWS
    }
  }
}
