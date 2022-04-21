resource "helm_release" "prometheus" {
  name             = "prometheus"
  chart            = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = var.PROM_HELM_CHART_VERSION
  namespace        = var.PROMETHEUS_NAMESPACE
  create_namespace = true
  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = true
  timeout          = 300
  values = [
    file("prom_values.yaml")
  ]
}

variable "PROMETHEUS_NAMESPACE" {
  description = "Namespace to deploy prom"
  default     = "prometheus"
  type        = string
}

variable "PROM_HELM_CHART_VERSION" {
  description = "Version of the Prom helm chart"
  default     = "15.8.4"
}
