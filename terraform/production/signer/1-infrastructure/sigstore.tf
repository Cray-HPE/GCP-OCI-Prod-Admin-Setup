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

  // Specifying a zone will create a zonal cluster instead of a regional one
  region     = var.cluster_zone
  project_id = var.project_id

  cluster_name        = var.cluster_name
  cluster_network_tag = var.cluster_network_tag

  network                       = module.network.network_self_link
  subnetwork                    = module.network.subnetwork_self_link
  cluster_secondary_range_name  = module.network.secondary_ip_range.0.range_name
  services_secondary_range_name = module.network.secondary_ip_range.1.range_name

  autoscaling_min_node = var.autoscaling_min_node
  autoscaling_max_node = var.autoscaling_max_node

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

  # TODO (priyawadhwa): Disable this once we have the intermediate cert
  enable_ca    = true
  ca_pool_name = "sigstore-ca"

  // KMS
  fulcio_keyring_name = "fulcio-keyring"
  fulcio_key_name     = "fulcio-intermediate-key"

  depends_on = [
    module.cluster,
    module.network
  ]
}

// Rekor
module "rekor" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/rekor"

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  // Network
  network = module.network.network_name

  // Storage
  attestation_bucket = var.attestation_bucket

  // KMS

  depends_on = [
    module.cluster,
    module.network
  ]
}

