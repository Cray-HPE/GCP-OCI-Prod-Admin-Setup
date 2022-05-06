variable "project_id" {
  type = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "ca_pool_name" {
  description = "Certificate authority pool name"
  type        = string
  default     = "sigstore"
}

variable "monitoring" {
  description = "Monitoring and alerting"
  type = object({
    enabled                 = bool
    fulcio_url              = string
    rekor_url               = string
    dex_url                 = string
    notification_channel_id = string
  })
  default = {
    enabled                 = false
    fulcio_url              = "fulcio.example.com"
    dex_url                 = "oauth2.example.com"
    rekor_url               = "rekor.example.com"
    notification_channel_id = ""
  }
}

// Optional values that can be overridden or appended to if desired.
variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "sigstore-prod"
}

variable "cluster_network_tag" {
  type    = string
  default = ""
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
  default     = "serviceAccount:github-actions@oci-signer-service-dev.iam.gserviceaccount.com"
}

// Storage 
variable "attestation_bucket" {
  type        = string
  description = "Name of the GCS bucket to store Rekor attestations in"
  default     = "rekor-oci-signer-service"
}


// Network variables
variable "network_name" {
  type        = string
  description = "Name of the private network to set up in"
  default     = "default-network"
}

variable "network_self_link" {
  type = string
  description = "Network self link"
  default = "https://www.googleapis.com/compute/v1/projects/shared-vpc-interconnect-202004/global/networks/default-network"
}

variable "subnetwork_name" {
  type        = string
  description = "Subnetwork name"
  default     = "sig-store"
}

variable "subnetwork_self_link" {
  type        = string
  description = "Subnetwork to use"
  default     = "https://www.googleapis.com/compute/v1/projects/shared-vpc-interconnect-202004/regions/us-central1/subnetworks/sig-store"
}

variable "secondary_ip_range_name_pod" {
  type        = string
  description = "IP range for pods"
  default     = "sigstore-prod-pod-range"
}

variable "secondary_ip_range_name_svc" {
  type        = string
  description = "IP range for services"
  default     = "sigstore-prod-svc-range"
}
