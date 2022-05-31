variable "project_id" {
  type = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "region" {
  description = "The region in which to create the VPC network"
  type        = string
}

// Optional values that can be overridden or appended to if desired.
variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "tekton"
}

variable "github_repo" {
  description = "Github repo for running Github Actions from."
  type        = string
  default     = "Cray-HPE/GCP-OCI-Prod-Admin-Setup"
}

variable "tekton_sa_name" {
  default     = "tekton-sa"
  description = "Name of the service accounts in GCP/GKE and k8s"
}

variable "tekton_working_namespace" {
  default     = "default"
  description = "Namespace where tekton workloads are running"
}

variable "REKOR_ADDRESS" {
  default     = "http://104.154.206.234"
  description = "URL for rekor"
  type        = string
}

variable "FULCIO_ADDRESS" {
  default     = "http://35.184.190.155"
  description = "URL for fulcio"
  type        = string
}

variable "TK_PIPELINE_HELM_CHART_VERSION" {
  default     = "0.2.3"
  type        = string
  description = "Helm chart version of tekton pipeline helm chart"
}

variable "TK_PIPELINE_NAMESPACE" {
  default     = "tekton-pipelines"
  type        = string
  description = "Namespace to deploy tekton charts"
}

variable "TK_PIPELINE_HELM_REPO" {
  type        = string
  description = "tekton pipeline helm chart"
  default     = "https://chainguard-dev.github.io/tekton-helm-charts"
}

variable "TK_DASHBOARD_HELM_CHART_VERSION" {
  default     = "0.2.1"
  type        = string
  description = "Tekton Dashboard of the helm chart to deploy"
}

variable "TK_DASHBOARD_HELM_REPO" {
  type        = string
  description = "tekton dashboard helm chart repo"
  default     = "https://chainguard-dev.github.io/tekton-helm-charts"
}

variable "TK_CHAINS_NAMESPACE" {
  default     = "tekton-chains"
  type        = string
  description = "Namespace to deploy tekton chains"
}

variable "TK_CHAINS_HELM_CHART_VERSION" {
  default     = "0.2.4"
  type        = string
  description = "Helm chart version of tekton chains to deploy"
}

variable "TK_CHAINS_HELM_REPO" {
  type        = string
  description = "tekton chains helm chart repo"
  default     = "https://chainguard-dev.github.io/tekton-helm-charts"
}

variable "PROMETHEUS_NAMESPACE" {
  description = "Namespace to deploy prom"
  default     = "prometheus"
  type        = string
}

variable "PROM_HELM_CHART_VERSION" {
  description = "Version of the Prom helm chart"
  default     = "15.8.7"
}


