// Private network
module "network" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/network?ref=b5aaa001b1705c9d8c954773ca64dbf35dc6b807"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name
}

// Bastion
module "bastion" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/bastion?ref=b5aaa001b1705c9d8c954773ca64dbf35dc6b807"

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
  region         = var.region
  cluster_zone   = var.cluster_zone
  project_id     = var.project_id
  project_number = var.project_number

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

// Cluster policies setup.
module "policy_bindings" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/policy_bindings?ref=b5aaa001b1705c9d8c954773ca64dbf35dc6b807"

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
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/mysql?ref=b5aaa001b1705c9d8c954773ca64dbf35dc6b807"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  network = module.network.network_self_link

  database_version = var.database_version

  depends_on = [
    module.network,
    module.cluster
  ]
}

// Fulcio
module "fulcio" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/fulcio?ref=b5aaa001b1705c9d8c954773ca64dbf35dc6b807"

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  # TODO: Disable this once we have the intermediate cert
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
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/rekor?ref=b5aaa001b1705c9d8c954773ca64dbf35dc6b807"

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

