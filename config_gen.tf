module "validate_email" {
  source  = "rhythmictech/errorcheck/terraform"
  version = "1.3.0"

  assert        = length(regexall("(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$)", var.admin_user_email)) > 0
  error_message = "The email provided for the admin account is invalid: ${var.admin_user_email}"

  use_jq = true
}

resource "random_password" "admin_password" {
  length      = 15
  special     = false
  min_lower   = 2
  min_numeric = 2
  min_upper   = 2
}
