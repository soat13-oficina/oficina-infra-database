# ADR 0001 — Consumo do state da plataforma e isolamento por workspace

- **Status:** Aceito
- **Data:** 2026-09-02
- **Contexto:** Tech Challenge SOAT 13 — Fase 3

## Contexto

Este repositório provisiona o banco gerenciado, mas o RDS não é autossuficiente:
depende de `vpc_id`, do *DB subnet group* e do `node_security_group_id` do
cluster EKS — todos criados no repositório `oficina-infra-k8s`, em outro state.

Além disso, o enunciado exige **deploy automático das branches de homologação e
produção**, o que implica duas instâncias de banco a partir do mesmo código.

## Decisão

### 1. Dependência via `terraform_remote_state`

```hcl
data "terraform_remote_state" "platform" {
  backend = "s3"
  config  = { bucket = var.state_bucket, key = "oficina/infra-k8s.tfstate", ... }
}
```

A dependência é **explícita, unidirecional e verificável**: se a plataforma não
existe, o `plan` falha imediatamente com "Unable to find remote state", e não
mais adiante com um erro obscuro de subnet inexistente.

Descartado: descobrir a VPC por `data "aws_vpc"` filtrando por tag `Name`.
Funciona, mas transforma o contrato entre repositórios em uma convenção de
nomenclatura implícita — renomear uma tag quebraria o `apply` sem que nada no
código indicasse a relação.

### 2. Isolamento de ambientes por `terraform workspace`

Um único código, dois states (`env:/hml/…` e `env:/prd/…` na mesma bucket), com
a configuração por ambiente num `map(object)` em `var.environments`. O
workspace `default` é **rejeitado** por um guard em `locals.tf` — sem ele, um
`apply` distraído criaria uma terceira instância de banco fora de qualquer
ambiente, cobrada e invisível.

Descartadas:

| Alternativa | Por que não |
|---|---|
| **Dois diretórios** (`envs/hml`, `envs/prd`) | Mais explícito, mas duplica o código e convida à divergência entre ambientes — foi exatamente isso que se quis evitar. |
| **Uma instância com dois databases lógicos** | Exigiria o provider `postgresql` (que precisa de rota de rede até um banco privado, inviável a partir do runner) ou um `null_resource` com `psql`. E uma saturação de CPU derrubaria os dois ambientes juntos. |
| **`for_each` sobre os ambientes num state só** | Um `destroy` de homologação passaria pelo mesmo state de produção; o *blast radius* de um erro humano cobriria os dois. |

### 3. Senha do banco fora do Terraform

`manage_master_user_password = true`: a AWS gera e guarda a credencial no
Secrets Manager. A senha **não passa pelo state** nem pelo repositório. A
pipeline da aplicação lê o segredo em tempo de deploy e materializa o `Secret`
do Kubernetes.

### 4. Identificador previsível como contrato

`oficina-db-hml` e `oficina-db-prd`. A pipeline da aplicação descobre endpoint e
credenciais com `aws rds describe-db-instances --db-instance-identifier`, sem
precisar ler o state deste repositório nem receber permissão sobre a bucket.
O acoplamento fica em uma string documentada, e não em uma dependência de state.

## Consequências

**Positivas**
- Homologação e produção compartilham 100% do código e divergem apenas em dados declarados em um único mapa, fácil de revisar num diff.
- Nenhuma credencial de banco em código, state ou log de pipeline.
- Um `destroy` de homologação não tem como alcançar produção.

**Negativas / mitigações**
- **Esquecer de selecionar o workspace** é o erro mais provável. Mitigado pelo guard em `locals.tf` e pelo `terraform workspace select -or-create` explícito na pipeline.
- **A credencial deste repositório precisa de leitura na key da plataforma** (`s3:GetObject`). Documentado no README.
- **Destruir a plataforma antes do banco deixa recursos órfãos.** A ordem correta de destruição está no README dos dois repositórios.
