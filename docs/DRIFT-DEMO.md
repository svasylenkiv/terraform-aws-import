# Демо: Import → Drift → Опис → No Drift

Сценарій відтворення ситуації drift після імпорту.

## Початковий стан

- Є S3 bucket `nord-dev-s3` в AWS (з тегами, encryption, versioning)
- Ресурс **не** в Terraform state

## Крок 1. Мінімальний конфіг + імпорт

Додай у `environments/dev/s3.tf`:

```hcl
resource "aws_s3_bucket" "nord_dev" {
  bucket = "nord-dev-s3"
}
```

Імпортуй (CLI — тільки в state, без apply):

```bash
cd environments/dev
terraform import -var-file=terraform.tfvars aws_s3_bucket.nord_dev nord-dev-s3
```

## Крок 2. Plan → бачимо drift

```bash
terraform plan -input=false -var-file=terraform.tfvars
```

**Результат:** Terraform хоче оновити ресурс — зняти теги `project`, `environment`, бо вони не описані в конфігу.

```
# aws_s3_bucket.nord_dev will be updated in-place
~ tags = {
    - "environment" = "dev" -> null
    - "project"     = "nord" -> null
  }
Plan: 0 to add, 1 to change, 0 to destroy.
```

## Крок 3. Описуємо ресурс

Додай теги до конфігу:

```hcl
resource "aws_s3_bucket" "nord_dev" {
  bucket = "nord-dev-s3"

  tags = {
    project     = "nord"
    environment = "dev"
  }
}
```

## Крок 4. Plan → no drift

```bash
terraform plan -input=false -var-file=terraform.tfvars
```

**Результат:**

```
No changes. Your infrastructure matches the configuration.
```

---

## Чому CLI import замість import block?

- `terraform import` (CLI) — тільки додає ресурс у state, не змінює AWS
- `import` block + `terraform apply` — імпортує **і** застосовує конфіг (змінює AWS)

Щоб побачити drift, потрібно імпортувати без apply — тоді state містить фактичний стан AWS, а конфіг мінімальний, і plan показує різницю.
