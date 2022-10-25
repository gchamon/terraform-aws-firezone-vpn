## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backup_bucket"></a> [backup\_bucket](#module\_backup\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.4.0 |
| <a name="module_validate_email"></a> [validate\_email](#module\_validate\_email) | rhythmictech/errorcheck/terraform | 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.backup_and_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_launch_template.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_route53_record.endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.wireguard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.aws_cloudwatch_agent_server_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.backup_and_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_user_email"></a> [admin\_user\_email](#input\_admin\_user\_email) | Creates pre-configured admin user with the provider email and a random password | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS Region | `string` | n/a | yes |
| <a name="input_desired_instances"></a> [desired\_instances](#input\_desired\_instances) | [WIP] used for high availability. Not implemented. This option has no effect | `number` | `1` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | The docker image used to launch Firezone. Override this with another image repo (e.g. ECR) to control the version. Useful for not depending on dockerhub SLA and for custom patches | `string` | `"firezone/firezone:0.6.4"` | no |
| <a name="input_enable_cloudwatch_metrics"></a> [enable\_cloudwatch\_metrics](#input\_enable\_cloudwatch\_metrics) | Optional: enable swap, memory and disk metrics with cloudwatch agent | `bool` | `false` | no |
| <a name="input_firezone_environment_variables"></a> [firezone\_environment\_variables](#input\_firezone\_environment\_variables) | Extra environment variables to pass to the Firezone container. See https://docs.firezone.dev/reference/env-vars | `any` | `{}` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Wireguard EC2 instance type. Controls CPU, Memory and Network resources | `string` | n/a | yes |
| <a name="input_internal_url"></a> [internal\_url](#input\_internal\_url) | The URL used to create an alias to the EC2 instance private IP | `string` | `null` | no |
| <a name="input_is_ecr_docker_image"></a> [is\_ecr\_docker\_image](#input\_is\_ecr\_docker\_image) | Tells whether the docker\_image comes from ECR. This will cause the EC2 instance to login to ECR using docker login before attempting to pull the image | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used to tag and create resources | `string` | `"vpn-wireguard-firezone"` | no |
| <a name="input_ssh_key_bucket"></a> [ssh\_key\_bucket](#input\_ssh\_key\_bucket) | Bucket to write SSH key to. The SSH key is used to connect to the wireguard instance via SSH | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet ids used to deploy instances to | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags used to tag resources with. Defaults to {}, in which case all resources are tagged with Name | `map(string)` | `{}` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | The EC2 Instance volume size | `number` | `8` | no |
| <a name="input_vpn_endpoint_url"></a> [vpn\_endpoint\_url](#input\_vpn\_endpoint\_url) | The endpoint url used to create the Wireguard config file | `string` | n/a | yes |
| <a name="input_web_url"></a> [web\_url](#input\_web\_url) | The web application URL used to access the administration portal | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Zone ID to create the route53 records in. The records are used to create the wireguard endpoint and the internal alias for SSH | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group"></a> [autoscaling\_group](#output\_autoscaling\_group) | n/a |
| <a name="output_backup_bucket"></a> [backup\_bucket](#output\_backup\_bucket) | n/a |
| <a name="output_endpoint_record"></a> [endpoint\_record](#output\_endpoint\_record) | n/a |
| <a name="output_instance_profile"></a> [instance\_profile](#output\_instance\_profile) | n/a |
| <a name="output_launch_template"></a> [launch\_template](#output\_launch\_template) | n/a |
| <a name="output_password"></a> [password](#output\_password) | n/a |
| <a name="output_policy"></a> [policy](#output\_policy) | n/a |
| <a name="output_private_key"></a> [private\_key](#output\_private\_key) | n/a |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | n/a |
| <a name="output_web_record"></a> [web\_record](#output\_web\_record) | n/a |
