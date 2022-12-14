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
  value = random_password.admin_password
}

output "endpoint_record" {
  value = aws_route53_record.endpoint
}

output "web_record" {
  value = aws_route53_record.web
}

output "backup_bucket" {
  value = module.backup_bucket
}

output "security_group" {
  value = aws_security_group.wireguard
}
