resource "helm_release" "prometheus" {
  name             = "prometheus-community"
  chart            = "https://prometheus-community.github.io/helm-charts"
  version          = var.PROM_HELM_CHART_VERSION
  namespace        = var.TK_PIPELINE_NAMESPACE
  create_namespace = true
  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = true
  values = [
    file("prom_values.yaml")
  ]
}

variable "PROM_HELM_CHART_VERSION" {
  description = "Version of the Prom helm chart"
  default = "PROM_HELM_CHART_VERSION15.8.1"
}