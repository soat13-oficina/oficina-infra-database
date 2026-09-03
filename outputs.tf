output "environment" {
  description = "Ambiente correspondente ao workspace selecionado (hml ou prd)."
  value       = local.environment
}

output "db_instance_identifier" {
  description = "Identificador da instancia RDS. E o contrato usado pela pipeline da aplicacao para descobrir endpoint e credenciais."
  value       = aws_db_instance.main.identifier
}

output "db_endpoint" {
  description = "Endpoint host:porta do PostgreSQL, usado no DB_URL da aplicacao."
  value       = "${aws_db_instance.main.address}:${aws_db_instance.main.port}"
}

output "db_address" {
  description = "Apenas o host do PostgreSQL."
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Porta do PostgreSQL."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Nome do database dentro da instancia."
  value       = aws_db_instance.main.db_name
}

output "master_user_secret_arn" {
  description = "ARN do secret no Secrets Manager com usuario/senha, gerenciado pelo proprio RDS."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "Security group da instancia - referencie-o para liberar novos consumidores (ex.: a Lambda de autenticacao)."
  value       = aws_security_group.rds.id
}

output "jdbc_url" {
  description = "URL JDBC pronta para o ConfigMap da aplicacao (credenciais vem do Secret, nao daqui)."
  value       = "jdbc:postgresql://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}
