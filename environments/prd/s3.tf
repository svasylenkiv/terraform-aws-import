# S3 bucket nord-prd-s3 (імпортовано)

resource "aws_s3_bucket" "nord_prd" {
  bucket = "nord-prd-s3"

  tags = {
    project     = "nord"
    environment = "prd"
  }
}
