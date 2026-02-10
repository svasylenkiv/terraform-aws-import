# terraform-aws-import

Репозиторій для імпорту існуючих AWS ресурсів у Terraform state. Призначений для акаунтів, де вже є інфраструктура, створена вручну або іншими інструментами, і її потрібно перевести під управління Terraform.

## Що це дає

- **Plan workflow** — перевірка відповідності конфігу та state (відстеження drift)
- **Import workflow** — пошук ресурсів за тегами і генерація конфігу для імпорту
- Ітеративний процес: імпорт → plan показує відмінності → оновлюєш .tf → plan знову без змін

## Передумови

- Terraform 1.12+ (для `terraform query` і bulk import)
- AWS account з існуючими ресурсами
- GitHub repo з налаштованими secrets

## Швидкий старт

### 1. Backend (S3 + DynamoDB)

Спочатку створи S3 bucket і DynamoDB table. **Рекомендовано локально** (щоб зберегти state):

```bash
cd bootstrap
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Або через GitHub Actions: Workflows → Bootstrap → Run workflow (plan, потім apply).

Буде створено:
- **Bucket:** `terraform-aws-import-terraform-state`
- **DynamoDB:** `terraform-aws-import-terraform-lock`

Кожне середовище має окремий state key: `dev/terraform.tfstate`, `stg/terraform.tfstate`, `prd/terraform.tfstate`.

### 2. GitHub Secrets та Environments

У Settings → Secrets and variables → Actions додай:

| Secret | Опис |
|--------|------|
| `AWS_ACCESS_KEY_ID` | IAM key для доступу до AWS |
| `AWS_SECRET_ACCESS_KEY` | Відповідний secret |

Створи GitHub Environments (Settings → Environments): `dev`, `stg`, `prd`. У кожному можна задати окремі secrets, якщо потрібно різні облікові дані на env.

Можна використовувати OIDC замість ключів — налаштуй `aws-actions/configure-aws-credentials` з `role-to-assume`.

### 3. Налаштуй запити для імпорту

Відредагуй `queries/discover-by-tags-<env>.tfquery.hcl` (dev, stg, prd) — укажи потрібні теги:

```hcl
filter {
  name   = "tag:Project"
  values = ["твій-проєкт"]
}
filter {
  name   = "tag:Environment"
  values = ["dev"]
}
```

### 4. Запуск workflows

| Workflow | Коли | Що робить |
|----------|------|-----------|
| **Bootstrap** | Manual | Створює S3 bucket + DynamoDB для state (запусти один раз) |
| **Terraform Plan** | PR або manual | `terraform plan` — показує drift, зміни (обирай dev/stg/prd) |
| **Terraform Import** | Manual | `terraform query` → згенерує `generated.tf` → артефакт (обирай dev/stg/prd) |

## Процес імпорту

```
1. Запусти "Terraform Import" workflow
2. Завантаж артефакт terraform-generated-config (generated.tf)
3. Переглянь generated.tf — resource + import blocks
4. Скопіюй потрібні блоки в main.tf або окремі *.tf
5. Видаліть import blocks після успішного apply (або залиш для історії)
6. Зроби apply (через workflow або terraform apply локально)
7. Запусти Plan — має бути "No changes"
```

## Одиночний імпорт (без bulk query)

Для одного ресурсу використовуй `import` block у `main.tf`:

```hcl
import {
  to = aws_instance.my_server
  id = "i-1234567890abcdef0"
}
```

Потім:

```bash
terraform plan -generate-config-out=generated.tf
# Переглянь generated.tf, скопіюй resource block
terraform apply
```

## Структура репозиторію

```
terraform-aws-import/
├── .github/workflows/
│   ├── bootstrap.yml           # Створює S3 + DynamoDB (запусти один раз)
│   ├── terraform-plan.yml      # Plan (PR + manual)
│   └── terraform-import.yml    # Query + generate config
├── bootstrap/
│   ├── main.tf                 # S3 bucket + DynamoDB table
│   └── terraform.tfvars
├── environments/
│   ├── dev/
│   ├── stg/
│   └── prd/
│       ├── main.tf             # окремий state key на env
│       └── terraform.tfvars
├── queries/
│   ├── discover-by-tags-dev.tfquery.hcl
│   ├── discover-by-tags-stg.tfquery.hcl
│   └── discover-by-tags-prd.tfquery.hcl
├── docs/
│   └── PLAN.md
└── README.md
```

## Теги в AWS

Для ефективного bulk import тегуй ресурси:

- `Project` — назва проєкту
- `Environment` — dev / stg / prd
- `ManagedBy` — terraform (після імпорту)

## Обмеження

- Не всі AWS ресурси підтримують `list` у tfquery — перевіряй [документацію провайдера](https://registry.terraform.io/providers/hashicorp/aws/latest)
- Terraform query доступний з v1.12; повноцінний search — з v1.14

## Детальний план

Деталі архітектури та workflow — у [docs/PLAN.md](docs/PLAN.md).
