resource "aws_s3_bucket" "backup" {
  bucket_prefix = "${var.name}-backup-"
  acl           = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 7
    }
  }

  tags = var.tags
}
