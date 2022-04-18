resource "helm_release" "tekton_pipelines" {
  name             = "tekton-pipelines"
  chart            = var.TK_PIPELINE_HELM_LOCAL_PATH
  version          = var.TK_PIPELINE_HELM_CHART_VERSION
  namespace        = var.TK_PIPELINE_NAMESPACE
  create_namespace = true
  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = true
  set {
    name  = "feature_flags.disable-affinity-assistant"
    value = "true"
  }
}

resource "helm_release" "tekton_dashboard" {
  name             = "tekton-dashboard"
  chart            = var.TK_DASHBOARD_HELM_LOCAL_PATH
  version          = var.TK_DASHBOARD_HELM_CHART_VERSION
  namespace        = var.TK_PIPELINE_NAMESPACE
  create_namespace = false
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = true
}

resource "helm_release" "tekton_chains" {
  name             = "tekton-chains"
  chart            = var.TK_CHAINS_HELM_LOCAL_PATH
  version          = var.TK_CHAINS_HELM_CHART_VERSION
  namespace        = var.TK_CHAINS_NAMESPACE
  create_namespace = true
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = true
  set {
    name  = "tenantconfig.artifacts\\.oci\\.format"
    value = "simplesigning"
  }
  set {
    name  = "tenantconfig.artifacts\\.oci\\.storage"
    value = "oci"
  }
  set {
    name  = "tenantconfig.artifacts\\.taskrun\\.format"
    value = "in-toto"
  }
  set {
    name  = "tenantconfig.signers\\.x509\\.fulcio\\.address" # Connect chains to fulcio service
    value = var.FULCIO_ADDRESS
  }
  set {
    name  = "tenantconfig.signers\\.x509\\.fulcio\\.enabled"
    value = "true"
  }
  set {
    name  = "tenantconfig.transparency\\.enabled"
    value = "true"
  }
  set {
    name  = "tenantconfig.transparency\\.url" # Connect chains to rekor service
    value = var.REKOR_ADDRESS
  }
}


variable "REKOR_ADDRESS" {
  default     = "https://rekor.sigstore.dev"
  description = "URL for rekor"
  type        = string
}

variable "FULCIO_ADDRESS" {
  default     = "https://fulcio.sigstore.dev/"
  description = "URL for fulcio"
  type        = string
}

variable "TK_PIPELINE_HELM_CHART_VERSION" {
  default     = "v0.1.0"
  type        = string
  description = "Helm chart version of tekton pipeline helm chart"
}

variable "TK_PIPELINE_NAMESPACE" {
  default     = "tekton-pipelines"
  type        = string
  description = "Namespace to deploy tekton charts"
}

variable "TK_PIPELINE_HELM_LOCAL_PATH" {
  type        = string
  description = "Path to local tekton pipeline helm chart"
  default = "../../../../tekton-helm-charts/charts/pipelines"
}

variable "TK_DASHBOARD_HELM_CHART_VERSION" {
  default     = "v0.1.0"
  type        = string
  description = "Tekton Dashboard of the helm chart to deploy"
}

variable "TK_DASHBOARD_HELM_LOCAL_PATH" {
  type        = string
  description = "Path to local tekton dashboard helm chart"
  default = "../../../../tekton-helm-charts/charts/dashboard"
}

variable "TK_CHAINS_NAMESPACE" {
  default     = "tekton-chains"
  type        = string
  description = "Namespace to deploy tekton chains"
}

variable "TK_CHAINS_HELM_CHART_VERSION" {
  default     = "v0.1.0"
  type        = string
  description = "Helm chart version of tekton chains to deploy"
}

variable "TK_CHAINS_HELM_LOCAL_PATH" {
  type        = string
  description = "Path to local tekton chains helm chart"
  default = "../../../../tekton-helm-charts/charts/chains"
}
