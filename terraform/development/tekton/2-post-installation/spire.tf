resource "helm_release" "spire" {
  name             = "spire"
  chart            = var.SPIRE_CHART_PATH
  version          = var.SPIRE_HELM_CHART_VERSION
  namespace        = var.SPIRE_NAMESPACE
  create_namespace = true
  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = false
  timeout          = 60
  set {
    name  = "trustDomain"
    value = "sig-spire.algol60.net"
  }

  set {
    name  = "fullyQualifiedTrustDomain"
    value = "https://sig-spire.algol60.net"
  }

  set {
    name  = "email"
    value = "pwadhwa@algol60.net"
  }

  set {
    name  = "loadBalancerIP"
    value = "35.232.144.34"
  }
}
