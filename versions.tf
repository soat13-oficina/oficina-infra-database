terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend parcial: bucket e region vem de backend.hcl (nao versionado).
  #   terraform init -backend-config=backend.hcl
  #
  # Este repositorio usa WORKSPACES (hml e prd). Com o backend S3, cada
  # workspace grava em env:/<workspace>/<key>, de modo que os dois ambientes
  # tem states independentes sem duplicar codigo.
  backend "s3" {
    key          = "oficina/infra-database.tfstate"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Layer       = "database"
      Environment = local.environment
      ManagedBy   = "terraform"
      Repo        = "oficina-infra-database"
    }
  }
}
