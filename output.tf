output "instance_profile" {
  value = aws_iam_instance_profile.this
}

output "launch_template" {
  value = aws_launch_template.instance
}

output "autoscaling_group" {
  value = aws_autoscaling_group.this
}

output "policy" {
  value = aws_iam_policy.backup_and_eip
}

output "private_key" {
  value = tls_private_key.this
}

output "password" {
  value = random_password.this
}

output "endpoint_record" {
  value = aws_route53_record.endpoint
}

output "web_record" {
  value = aws_route53_record.web
}

output "internal_record" {
  value = aws_route53_record.internal
}

output "backup_bucket" {
  value = aws_s3_bucket.backup
}

output "security_group" {
  value = aws_security_group.wireguard
}
