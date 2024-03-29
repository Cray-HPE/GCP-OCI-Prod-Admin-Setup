variable "project_id" {
  type = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "project_number" {
  type        = number
  description = "Project number associated with project_id"
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

// Cluster variables
// Optional values that can be overridden or appended to if desired.
variable "cluster_name" {
  description = "The name to give the new Kubernetes cluster."
  type        = string
  default     = "sigstore-prod"
}

variable "cluster_zone" {
  description = "The zone to create the k8s cluster in."
  type        = string
  default     = "us-central1-a"
}

variable "autoscaling_min_node" {
  type    = number
  default = 3
}

variable "autoscaling_max_node" {
  type    = number
  default = 5
}


variable "cluster_network_tag" {
  type    = string
  default = ""
}

// CLUSTER DATABASE ENCRYPTION

variable "database_encryption_state" {
  type    = string
  default = "ENCRYPTED"
}

variable "database_encryption_key_name" {
  type    = string
  default = "projects/oci-signer-service-dev/locations/global/keyRings/gke-secrets/cryptoKeys/GKE-Shared-Cluster"
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

// MySQL Database
variable "database_version" {
  type        = string
  description = "MySQL database version."
  default     = "MYSQL_8_0"
}

