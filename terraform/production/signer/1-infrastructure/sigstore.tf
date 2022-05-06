// TODO: Pin source to commits or releases

// Private network
module "network" {
  source = "../../modules/network"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  network_name    = var.network_name
  subnetwork_name = var.subnetwork_name
}

// Bastion
module "bastion" {
  source = "../../modules/bastion"

  project_id         = var.project_id
  region             = var.region
  network            = var.network_self_link
  subnetwork         = var.subnetwork_self_link
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

  cluster_name        = var.cluster_name
  cluster_network_tag = var.cluster_network_tag

  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  cluster_secondary_range_name  = var.secondary_ip_range_name_pod
  services_secondary_range_name = var.secondary_ip_range_name_svc

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

  network = format("projects/%s/global/networks/%s", var.project_id, var.network_name)

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
  network = var.network_name

  // Storage
  attestation_bucket = var.attestation_bucket

  // KMS

  depends_on = [
    module.cluster,
    module.network
  ]
}

