#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

variable "network_name" {
  default     = "tekton-ci-network"
  type        = string
  description = "Name of the network to deploy too"
}

variable "subnetwork_name" {
  default     = "tekton-ci-subnet"
  type        = string
  description = "Name of the subnetwork to deploy too"
}

variable "project_id" {
  type = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
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

variable "cluster_zone" {
  description = "The zone in which to create the k8s cluster"
  type        = string
  default     = "us-central1-a"
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



// CLUSTER DATABASE ENCRYPTION
variable "database_encryption_state" {
  type    = string
  default = "ENCRYPTED"
}

variable "database_encryption_key_name" {
  type    = string
  default = "projects/oci-tekton-service-dev/locations/global/keyRings/gke-secrets/cryptoKeys/tekton-dev"
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
