module "backup_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket_prefix = "${var.name}-backup-"
  acl           = "private"

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      enabled = true
      id      = "expire-old-backups"

      noncurrent_version_expiration = {
        days = 7
      }
    }
  ]

  tags = var.tags
}

moved {
  from = aws_s3_bucket.backup
  to = module.backup_bucket.aws_s3_bucket.this[0]
}
