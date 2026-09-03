locals {
  environment = terraform.workspace

  # Falha cedo e com mensagem legivel quando alguem esquece de selecionar o
  # workspace. Sem isto, o erro apareceria muito depois como "key not found"
  # na indexacao de var.environments, ou pior: um apply no workspace default
  # criaria uma terceira instancia de banco fora de qualquer ambiente.
  cfg = try(
    var.environments[local.environment],
    file("ERRO: workspace '${terraform.workspace}' invalido. Rode 'terraform workspace select hml' ou 'terraform workspace select prd' antes do plan/apply.")
  )

  identifier = "${var.project}-db-${local.environment}"
}
