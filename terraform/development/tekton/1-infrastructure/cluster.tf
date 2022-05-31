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
  // The double slash '//' syntax represents the submodule in the git directory
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/gke_cluster"

  region               = var.region
  project_id           = var.project_id
  node_pool_name       = var.cluster_name
  cluster_name         = var.cluster_name
  initial_node_count   = 3
  autoscaling_min_node = 3
  autoscaling_max_node = 10

  network                       = module.network.network_name
  subnetwork                    = module.network.subnetwork_self_link
  master_ipv4_cidr_block        = var.master_ipv4_cidr_block
  cluster_secondary_range_name  = module.network.secondary_ip_range.0.range_name
  services_secondary_range_name = module.network.secondary_ip_range.1.range_name

  bastion_ip_address = module.bastion.ip_address

  depends_on = [
    module.bastion,
    module.network
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
