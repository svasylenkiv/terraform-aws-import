# Як імпортувати ресурси через workflow

## Почому два способи?

1. **Terraform Import (Discover)** — для *bulk import*: шукає ресурси за тегами через `terraform query`. Підтримує не всі типи (EC2, VPC — так; S3 — потрібно перевіряти).
2. **Ручний імпорт** — додаєш `import` block + `resource` в `.tf` і запускаєш **Terraform Plan/Apply** з action `apply`.

## Self-service: імпорт через workflow

### Крок 1. Додай import block і resource у конфіг

У `environments/<env>/` створіть або додайте в `.tf`:

```hcl
# environments/dev/s3.tf

import {
  to = aws_s3_bucket.my_bucket
  id = "назва-bucket-в-aws"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "назва-bucket-в-aws"

  tags = {
    project     = "nord"
    environment = "dev"
  }
}
```

Для інших типів дивись [Import ID](https://developer.hashicorp.com/terraform/language/import#resource-identity) в документації провайдера.

### Крок 2. Запусти Plan

Actions → **Terraform Plan / Apply** → Run workflow:
- **Environment:** dev (або stg, prd)
- **Action:** plan

Перевір, що план показує тільки import, без destroy.

### Крок 3. Запусти Apply

Actions → **Terraform Plan / Apply** → Run workflow:
- **Environment:** dev
- **Action:** apply

### Крок 4. Прибери import block

Після успішного apply видали блок `import { ... }` з файлу — він потрібен лише один раз.

---

## Альтернатива: Terraform Import (Discover)

Для ресурсів з підтримкою `terraform query` (наприклад EC2):

1. Онови `queries/discover-by-tags-<env>.tfquery.hcl` — фільтри за тегами.
2. Запусти **Terraform Import (Discover)** → Run workflow.
3. Завантаж артефакт `terraform-generated-config-<env>`.
4. Скопіюй `resource` та `import` blocks з `generated.tf` у `environments/<env>/`.
5. Запусти **Terraform Plan/Apply** з action **apply**.

---

## Чому я не використав workflow для nord-dev-s3 і nord-prd-s3

1. **Terraform query** — список типів для bulk import обмежений; S3 bucket може не підтримуватися.
2. **Apply** — у workflow не було опції apply, тільки plan.

Тепер у workflow є action **apply**, тож імпорт можна робити повністю через GitHub Actions.
