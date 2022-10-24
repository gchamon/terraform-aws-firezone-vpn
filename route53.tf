resource "aws_route53_record" "web" {
  name = var.web_url

  type    = "A"
  zone_id = var.zone_id
  ttl     = 300

  records = [aws_eip.this.public_ip]
}

resource "aws_route53_record" "endpoint" {
  name = var.vpn_endpoint_url

  type    = "A"
  zone_id = var.zone_id
  ttl     = 300

  records = [aws_eip.this.public_ip]
}
