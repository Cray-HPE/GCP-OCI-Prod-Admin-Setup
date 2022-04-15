module "external_secrets" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/external_secrets"

  external_secrets_chart_version          = var.external_secrets_chart_version
  external_secrets_chart_values_yaml_path = "../helm-charts-values/external-secrets.yaml"
  project_id                              = var.project_id
}
