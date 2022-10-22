data "aws_iam_policy_document" "backup_and_eip" {
  statement {
    actions = [
      "ec2:AssociateAddress"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:HeadObject",
      "s3:ListBucket",
      "s3:HeadBucket"
    ]

    resources = [
      "${aws_s3_bucket.backup.arn}/*",
      aws_s3_bucket.backup.arn
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "backup_and_eip" {
  name   = var.name
  policy = data.aws_iam_policy_document.backup_and_eip.json
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name = var.name
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.backup_and_eip.arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count      = (var.enable_cloudwatch_metrics ? 1 : 0)
  policy_arn = data.aws_iam_policy.aws_cloudwatch_agent_server_policy.arn
  role       = aws_iam_role.this.name
}
