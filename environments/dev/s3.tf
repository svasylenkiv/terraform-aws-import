# S3 bucket nord-dev-s3 (імпортовано)

resource "aws_s3_bucket" "nord_dev" {
  bucket = "nord-dev-s3"

  tags = {
    project     = "nord"
    environment = "dev"
  }
}
