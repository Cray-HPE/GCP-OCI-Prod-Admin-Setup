data "google_client_config" "current" {
}

data "google_container_cluster" "sigstore_prod" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.cluster_zone
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.sigstore_prod.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.sigstore_prod.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
  proxy_url              = "socks5://localhost:8118"
}

provider "helm" {
  kubernetes {
    host  = data.google_container_cluster.sigstore_prod.endpoint
    token = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.sigstore_prod.master_auth[0].cluster_ca_certificate,
    )
    proxy_url = "socks5://localhost:8118"
  }
}

provider "kubectl" {
  host = data.google_container_cluster.sigstore_prod.endpoint
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.sigstore_prod.master_auth[0].cluster_ca_certificate,
  )
  token            = data.google_client_config.current.access_token
  load_config_file = false
}
