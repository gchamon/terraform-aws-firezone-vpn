docker run --rm \
  --volume "$PWD:/terraform-docs" \
  --user "$(id -u)" \
  quay.io/terraform-docs/terraform-docs \
  markdown /terraform-docs > "$PWD"/MODULE_ARGUMENTS.md