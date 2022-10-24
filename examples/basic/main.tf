data "aws_vpc" "default" {
  tags = {
    Name = "default"
  }
}

data "aws_subnet" "default" {
  tags = {
    Name = "default"
  }
}

module "ssh-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket_prefix = "firezone-ssh-keys-"
  acl           = "private"
  versioning = {
    enabled = true
  }
  lifecycle_rule = [
    {
      id      = "expire-old-keys"
      enabled = true

      noncurrent_version_expiration = {
        days = 3
      }
    }
  ]
}

data "aws_route53_zone" "speedy-way" {
  name = "speedy-way.xyz"
}

module "vpn" {
  source = "github.com/gchamon/terraform-aws-firezone-vpn"

  name             = "firezone-poc"
  aws_region       = "us-east-1"
  zone_id          = data.aws_route53_zone.speedy-way.id
  instance_type    = "t2.micro"
  subnet_ids       = [data.aws_subnet.default.id]
  ssh_key_bucket   = module.ssh-bucket.s3_bucket_id
  web_url          = "vpn.${data.aws_route53_zone.speedy-way.name}"
  vpn_endpoint_url = "endpoint.vpn.${data.aws_route53_zone.speedy-way.name}"
  internal_url     = "internal.vpn.${data.aws_route53_zone.speedy-way.name}"
  admin_user_email = "gabriel.chamon@tutanota.com"
}
