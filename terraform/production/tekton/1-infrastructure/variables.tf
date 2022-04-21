variable "network_name" {
  default     = "oci-build-service"
  type        = string
  description = "Name of the network to deploy too"
}

variable "subnetwork_name" {
  default     = "primary-us-central-builder"
  type        = string
  description = "Name of the subnetwork to deploy too"
}

variable "secondary_ip_range_name_pod" {
  type        = string
  description = "IP range for pods"
  default     = "pod-range"
}

variable "secondary_ip_range_name_svc" {
  type        = string
  description = "IP range for services"
  default     = "svc-range"
}


variable "project_id" {
  type = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "network_self_link" {
  type    = string
  default = "https://www.googleapis.com/compute/v1/projects/oci-tekton-service-dev/global/networks/oci-build-service"
}


variable "subnetwork_self_link" {
  type        = string
  description = "Subnetwork to use"
  default     = "https://www.googleapis.com/compute/v1/projects/oci-tekton-service-dev/regions/us-central1/subnetworks/primary-us-central-builder"
}



// Optional values that can be overridden or appended to if desired.
variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "tekton"
}

variable "env" {
  description = "environment for deployment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The region in which to create the VPC network"
  type        = string
}

variable "github_repo" {
  description = "Github repo for running Github Actions from."
  type        = string
  default     = "Cray-HPE/GCP-OCI-Prod-Admin-Setup"
}

// We don't actually need this but it's required by the bastion module
// So just assign it to the github-actions SA, which already has the permissions that will be granted
// in the bastion module
variable "tunnel_accessor_sa" {
  type        = string
  description = "Email of group to give access to the tunnel to"
  default     = "serviceAccount:github-actions@oci-tekton-service-dev.iam.gserviceaccount.com"
}
