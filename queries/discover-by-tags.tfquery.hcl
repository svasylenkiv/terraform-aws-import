# Query для bulk import — dev
# Змініть values на ваші теги.

list "aws_instance" "import_candidates" {
  provider = aws
  limit    = 100
  config {
    filter {
      name   = "tag:Project"
      values = ["terraform-aws-import"]
    }
    filter {
      name   = "tag:Environment"
      values = ["dev"]
    }
    filter {
      name   = "instance-state-name"
      values = ["running", "stopped"]
    }
  }
}

# Додайте інші типи за потреби:
# list "aws_vpc" "import_candidates" { ... }
# list "aws_security_group" "import_candidates" { ... }
# list "aws_s3_bucket" "import_candidates" { ... }
