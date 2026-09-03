# Dependencia explicita da camada de plataforma (repo oficina-infra-k8s):
# rede, subnet group de banco e o security group dos worker nodes do EKS.
#
# O sentido da dependencia (plataforma -> banco, nunca o contrario) e a razao
# de nao usar data sources por tag estao registrados em
# docs/adr/0001-consumo-do-state-da-plataforma.md.
#
# Se este data source falhar com "Unable to find remote state", a plataforma
# ainda nao foi provisionada: rode o apply de oficina-infra-k8s primeiro.
data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.platform_state_key
    region = var.aws_region
  }
}

locals {
  platform                   = data.terraform_remote_state.platform.outputs
  vpc_id                     = local.platform.vpc_id
  database_subnet_group_name = local.platform.database_subnet_group_name
  node_security_group_id     = local.platform.node_security_group_id
}
