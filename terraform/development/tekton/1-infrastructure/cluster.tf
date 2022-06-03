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

resource "google_container_registry" "registry" {
  project  = var.project_id
  location = "US"
}

data "google_project" "project" {
  project_id = var.project_id
}

// Private network
module "network" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/network"

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name
}

// Bastion
module "bastion" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/bastion"

  project_id         = var.project_id
  region             = var.region
  network            = module.network.network_name
  subnetwork         = module.network.subnetwork_self_link
  tunnel_accessor_sa = var.tunnel_accessor_sa
  depends_on = [
    module.network
  ]
}

module "cluster" {
  source = "../../modules/gke_cluster"

  // Specifying a zone will create a zonal cluster instead of a regional one
  region     = var.region
  project_id = var.project_id

  cluster_name        = var.cluster_name
  cluster_network_tag = var.cluster_network_tag

  network                       = module.network.network_self_link
  subnetwork                    = module.network.subnetwork_self_link
  cluster_secondary_range_name  = module.network.secondary_ip_range.0.range_name
  services_secondary_range_name = module.network.secondary_ip_range.1.range_name

  autoscaling_min_node = var.autoscaling_min_node
  autoscaling_max_node = var.autoscaling_max_node

  database_encryption_state    = var.database_encryption_state
  database_encryption_key_name = var.database_encryption_key_name

  bastion_ip_address = module.bastion.ip_address

  depends_on = [
    module.network,
    module.bastion
  ]
}

resource "random_id" "suffix" {
  byte_length = 4
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = "172.16.0.16/28"
}

//needed till https://github.com/sigstore/scaffolding/pull/123/files is merged
resource "google_compute_firewall" "master-webhooks" {
  name    = "gke-${var.cluster_name}-webhooks-${random_id.suffix.hex}"
  project = var.project_id

  network = module.network.network_name

  direction = "INGRESS"


  source_ranges = [var.master_ipv4_cidr_block]

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  depends_on = [module.cluster]
}

// Cluster policies setup.
module "policy_bindings" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/policy_bindings"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name
  github_repo  = var.github_repo
}
