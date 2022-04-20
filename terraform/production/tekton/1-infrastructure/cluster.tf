variable "network_name" {
  default = "oci-build-service"
  type = string
  description = "Name of the network to deploy too"
}

variable "subnetwork_name" {
  default = "primary-us-central-builder"
  type = string
  description = "Name of the subnetwork to deploy too"
}

data "google_compute_network" "primary" {
  name = var.network_name
}

data "google_compute_subnetwork" "sub"{
  name = var.subnetwork_name
}

// Bastion
module "bastion" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/bastion"

  project_id         = var.project_id
  region             = var.region
  network            = data.google_compute_network.primary.name
  subnetwork         = var.subnetwork_name
  tunnel_accessor_sa = var.tunnel_accessor_sa
}

module "cluster" {
  // The double slash '//' syntax represents the submodule in the git directory
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/gke_cluster"

  region     = var.region
  project_id = var.project_id
  node_pool_name = var.cluster_name
  cluster_name = var.cluster_name
  initial_node_count = 3
  autoscaling_max_node = 10



  network            = data.google_compute_network.primary.name
  subnetwork         = var.subnetwork_name
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  cluster_secondary_range_name  = "pod-range"
  services_secondary_range_name = "svc-range"

  bastion_ip_address = module.bastion.ip_address

  depends_on = [
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
  name      = "gke-${var.cluster_name}-webhooks-${random_id.suffix.hex}"
  project   = var.project_id

  network            = data.google_compute_network.primary.name
  direction = "INGRESS"


  source_ranges = [var.master_ipv4_cidr_block]

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  //target_tags = [local.cluster_network_tag]

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
