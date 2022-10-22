data "aws_vpc" "this" {
  tags = {
    name = "default"
  }
}

data "aws_subnet" "this" {
  tags = {
    name = "default"
  }
}

data "aws_route53_zone" "this" {
  name = "example.com"
}

resource "aws_s3_bucket" "ssh" {
  bucket_prefix = "subspace-ssh-"
  acl           = "private"
  versioning {
    enabled = true
  }
  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 3
    }
  }
}

module "vpn" {
  source           = "../../"
  aws_region       = "us-east-1"
  zone_id          = data.aws_route53_zone.this.id
  allowed_ips      = [data.aws_vpc.this.cidr_block]
  instance_type    = "t2.micro"
  subnet_ids       = [data.aws_subnet.this.id]
  ssh_key_bucket   = aws_s3_bucket.ssh.bucket
  vpn_endpoint_url = "endpoint.vpn.${data.aws_route53_zone.this.name}"
  internal_url     = "intenal.vpn.${data.aws_route53_zone.this.name}"
  web_url          = "vpn.${data.aws_route53_zone.this.name}"
}
