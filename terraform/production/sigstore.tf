// TODO: Pin source to commits or releases

// Private network
module "network" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/network"

  region     = var.region
  project_id = var.project_id

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

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  network                       = module.network.network_self_link
  subnetwork                    = module.network.subnetwork_self_link
  cluster_secondary_range_name  = module.network.secondary_ip_range.0.range_name
  services_secondary_range_name = module.network.secondary_ip_range.1.range_name

  bastion_ip_address = module.bastion.ip_address

  depends_on = [
    module.network,
    module.bastion
  ]
}

// Cluster policies setup.
module "policy_bindings" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/policy_bindings"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name
  github_repo  = var.github_repo

  depends_on = [
    module.network
  ]
}

// MYSQL is used as the database for Trillian to store entries in
module "mysql" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/mysql"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  network = module.network.network_self_link

  depends_on = [
    module.network,
    module.cluster
  ]
}

// Fulcio
module "fulcio" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/fulcio"

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  // Don't enable GCP CA service since we're using a provided intermediate
  enable_ca    = false
  ca_pool_name = "sigstore-ca"

  // KMS
  fulcio_keyring_name = "fulcio-keyring"
  fulcio_key_name     = "fulcio-intermediate-key"

  depends_on = [
    module.cluster,
    module.network
  ]
}

