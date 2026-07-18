# terraform-aws-secure-vpc

A production-ready Terraform module that provisions a secure, multi-tier AWS VPC following the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) best practices. It deploys a fully routed network with three isolated subnet tiers — **Public**, **Private (Compute)**, and **Database** — spread across multiple Availability Zones.

---

## Architecture Overview

```
                          ┌──────────────────────────────────────────┐
                          │              AWS VPC (10.0.0.0/16)        │
                          │                                          │
  Internet ──── IGW ────►│  ┌──────────────────────────────────────┐ │
                          │  │         PUBLIC SUBNETS               │ │
                          │  │  (Load Balancers / NAT Gateways)     │ │
                          │  │  10.0.1.0/24 · 10.0.2.0/24 ...      │ │
                          │  └───────────────┬──────────────────────┘ │
                          │                  │ NAT Gateway             │
                          │  ┌───────────────▼──────────────────────┐ │
                          │  │         PRIVATE SUBNETS              │ │
                          │  │  (EC2 / ECS / EKS workloads)         │ │
                          │  │  10.0.10.0/24 · 10.0.11.0/24 ...    │ │
                          │  └──────────────────────────────────────┘ │
                          │                                          │
                          │  ┌──────────────────────────────────────┐ │
                          │  │         DATABASE SUBNETS             │ │
                          │  │  (RDS / ElastiCache — VPC-only)      │ │
                          │  │  10.0.20.0/24 · 10.0.21.0/24 ...    │ │
                          │  └──────────────────────────────────────┘ │
                          └──────────────────────────────────────────┘
```

### Key Design Decisions

| Concern | Decision |
|---|---|
| **Internet access (public)** | Internet Gateway (IGW) attached to the VPC; public subnets route `0.0.0.0/0` → IGW |
| **Internet access (private)** | NAT Gateway placed in a public subnet; private subnets route outbound traffic → NAT GW |
| **Database isolation** | Database route table has **no default route** — traffic is restricted to intra-VPC only |
| **High-availability NAT** | One NAT Gateway per AZ by default; single-NAT mode available to reduce costs in non-prod |
| **IP assignment** | Public subnets assign public IPs automatically; private and database subnets do not |

---

## Features

- ✅ Multi-AZ deployment across a configurable number of Availability Zones
- ✅ Three isolated subnet tiers: **Public**, **Private**, and **Database**
- ✅ Internet Gateway for public-facing resources (e.g., ALBs)
- ✅ NAT Gateway with Elastic IP for private subnet egress
- ✅ Flexible NAT strategy: **single shared** (cost-saving) or **one per AZ** (HA)
- ✅ Dedicated, isolated routing table for database subnets (no internet route)
- ✅ Consistent resource tagging with `Environment` and `ManagedBy` labels
- ✅ Input validation for environment names and CIDR blocks
- ✅ GitHub Actions CI pipeline for format checks and validation

---

## Requirements

| Tool | Minimum Version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.3.0` |
| [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest) | `>= 5.0.0` |
| AWS credentials | Configured via env vars, `~/.aws/credentials`, or IAM role |

---

## Usage

### Minimal example

```hcl
module "vpc" {
  source = "github.com/your-org/terraform-aws-secure-vpc"

  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}
```

### Development environment (single NAT Gateway, cost-optimized)

```hcl
module "vpc_dev" {
  source = "github.com/your-org/terraform-aws-secure-vpc"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones    = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

  # Single NAT saves ~$32/month per eliminated gateway in non-prod environments
  enable_single_nat_gateway = true

  tags = {
    Project    = "SecureInfrastructure"
    Owner      = "DevOpsTeam"
    CostCenter = "101-R&D"
  }
}
```

### Production environment (one NAT Gateway per AZ — high availability)

```hcl
module "vpc_prod" {
  source = "github.com/your-org/terraform-aws-secure-vpc"

  environment = "prod"
  vpc_cidr    = "172.16.0.0/16"

  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs   = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnet_cidrs  = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
  database_subnet_cidrs = ["172.16.20.0/24", "172.16.21.0/24", "172.16.22.0/24"]

  # Each AZ gets its own NAT Gateway — if one AZ fails, others remain unaffected
  enable_single_nat_gateway = false

  tags = {
    Project     = "SecureInfrastructure"
    Owner       = "Platform"
    Environment = "Production"
  }
}
```

> A fully runnable example is available in [`examples/simple-vpc/`](./examples/simple-vpc/).

---

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `environment` | Deployment environment. Must be one of: `dev`, `qa`, `staging`, `prod`. | `string` | `"dev"` | no |
| `vpc_cidr` | Primary CIDR block for the VPC (e.g. `10.0.0.0/16`). | `string` | `"10.0.0.0/16"` | no |
| `availability_zones` | List of AWS Availability Zones where subnets will be deployed. Minimum 2 recommended. | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` | no |
| `public_subnet_cidrs` | List of CIDR blocks for the public subnets (one per AZ). | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | no |
| `private_subnet_cidrs` | List of CIDR blocks for the private (compute) subnets (one per AZ). | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]` | no |
| `database_subnet_cidrs` | List of CIDR blocks for the database subnets (one per AZ). | `list(string)` | `["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]` | no |
| `enable_single_nat_gateway` | If `true`, a single shared NAT Gateway is created (lower cost). If `false`, one NAT Gateway is created per AZ (high availability). | `bool` | `true` | no |
| `tags` | Additional key-value tags to attach to all created resources. | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | The ID of the created VPC. |
| `vpc_cidr_block` | The primary CIDR block of the VPC. |
| `public_subnet_ids` | List of IDs of the public subnets. |
| `private_subnet_ids` | List of IDs of the private subnets. |
| `database_subnet_ids` | List of IDs of the database subnets. |
| `internet_gateway_id` | The ID of the Internet Gateway. |
| `nat_gateway_public_ips` | List of public Elastic IPs associated with the NAT Gateway(s). |

---

## Resources Created

The following AWS resources are provisioned by this module:

| Resource | Count | Description |
|---|---|---|
| `aws_vpc` | 1 | The main VPC |
| `aws_internet_gateway` | 1 | Internet Gateway for public subnet access |
| `aws_subnet` (public) | N (one per AZ) | Public subnets for ALBs and NAT Gateways |
| `aws_subnet` (private) | N (one per AZ) | Private subnets for compute workloads |
| `aws_subnet` (database) | N (one per AZ) | Isolated database subnets |
| `aws_eip` | 1 or N | Elastic IPs for NAT Gateways |
| `aws_nat_gateway` | 1 or N | NAT Gateway(s) in the public subnet(s) |
| `aws_route_table` (public) | 1 | Routes `0.0.0.0/0` → IGW |
| `aws_route_table` (private) | N (one per AZ) | Routes `0.0.0.0/0` → NAT GW |
| `aws_route_table` (database) | 1 | Local VPC routes only (no internet access) |
| `aws_route_table_association` | 3×N | Associates each subnet with its route table |

> **N** = number of AZs / subnet CIDRs provided.

---

## NAT Gateway Strategy

This module supports two NAT Gateway deployment strategies, controlled by `enable_single_nat_gateway`:

### Single NAT Gateway (`enable_single_nat_gateway = true`)
A single NAT Gateway is deployed in the **first public subnet**. All private subnets route their outbound traffic through it.

- ✅ Lower cost (~$32/month per gateway saved)
- ✅ Ideal for `dev`, `qa`, and `staging` environments
- ❌ Single point of failure — if the AZ hosting the NAT GW goes down, all private subnets lose internet access

### NAT Gateway per AZ (`enable_single_nat_gateway = false`)
One NAT Gateway is deployed **in each public subnet** (one per AZ). Each private subnet routes traffic to the NAT GW within the same AZ.

- ✅ Fully highly available
- ✅ Reduces cross-AZ data transfer costs for egress traffic
- ✅ Recommended for `prod` environments
- ❌ Higher cost: NAT GW hourly rate × number of AZs

---

## Subnet Routing Summary

| Subnet Tier | Route `0.0.0.0/0` → | Internet Access |
|---|---|---|
| **Public** | Internet Gateway | ✅ Inbound & Outbound |
| **Private** | NAT Gateway | ✅ Outbound only |
| **Database** | *(none)* | ❌ VPC-local only |

---

## CI/CD Pipeline

This repository includes a **GitHub Actions** workflow at [`.github/workflows/terraform.yaml`](./.github/workflows/terraform.yaml) that runs automatically on every `push` or `pull_request` targeting the `main` branch.

### Pipeline Steps

| Step | Command | Description |
|---|---|---|
| **Checkout** | `actions/checkout@v4` | Clones the repository |
| **Setup Terraform** | `hashicorp/setup-terraform@v3` | Installs Terraform `1.5.0` |
| **Init** | `terraform init -backend=false` | Downloads provider plugins (no remote backend needed) |
| **Format Check** | `terraform fmt -check -recursive` | Fails if code is not properly formatted |
| **Validate** | `terraform validate -no-color` | Validates HCL syntax and internal consistency |

---

## Examples

| Example | Description |
|---|---|
| [`examples/simple-vpc/`](./examples/simple-vpc/) | A single-environment VPC for development with a single NAT Gateway and 2 AZs |

---

## Project Structure

```
terraform-aws-secure-vpc/
├── main.tf              # VPC and Internet Gateway
├── subnets.tf           # Public, Private, and Database subnets
├── nat.tf               # Elastic IPs and NAT Gateways
├── routing.tf           # Route tables and associations
├── variables.tf         # Input variable declarations with validation
├── outputs.tf           # Output value declarations
├── versions.tf          # Terraform and provider version constraints
├── examples/
│   └── simple-vpc/      # Runnable example for a dev environment
│       ├── main.tf
│       ├── outputs.tf
│       └── providers.tf
└── .github/
    └── workflows/
        └── terraform.yaml  # CI pipeline (fmt + validate)
```

---

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/your-org/terraform-aws-secure-vpc.git
cd terraform-aws-secure-vpc/examples/simple-vpc

# 2. Configure your AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# 3. Initialize Terraform
terraform init

# 4. Preview the execution plan
terraform plan

# 5. Apply the infrastructure
terraform apply
```

---

## License

This project is licensed under the [MIT License](./LICENSE).
