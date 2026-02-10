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
