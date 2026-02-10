# S3 bucket nord-dev-s3 (імпортовано)
# Після імпорту додали tags — drift зник

resource "aws_s3_bucket" "nord_dev" {
  bucket = "nord-dev-s3"

  tags = {
    project     = "nord"
    environment = "dev"
  }
}
