data "google_client_config" "current" {
}

data "google_container_cluster" "sigstore_prod" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region
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

resource "helm_release" "trillian" {
  name             = "trillian"
  repository       = "https://sigstore.github.io/helm-charts"
  chart            = "trillian"
  namespace        = "trillian-system"
  create_namespace = false
  atomic           = true
  version          = "0.1.6"

  values = [
    <<EOF
    enabled: true
    namespace:
      name: trillian-system
      create: false
    fullnameOverride: trillian
    forceNamespace: trillian-system
    serviceAccountName:
      logServer: trillian-logserver
      logSigner: trillian-logsigner
    logServer:
      enabled: true
      name: logserver
      fullnameOverride: trillian-logserver
      portRPC: 8090
      portHTTP: 8091
      replicaCount: 3
      resources:
        requests:
          memory: "1G"
          cpu: "0.5"
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: sigstore-prod-mysql-sa@oci-signer-service-dev.iam.gserviceaccount.com
      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8091"
      securityContext:
        runAsNonRoot: true
        runAsUser: 65533
    logSigner:
      enabled: true
      name: logsigner
      portRPC: 8090
      portHTTP: 8091
      fullnameOverride: trillian-logsigner
      resources:
        requests:
          memory: "1G"
          cpu: "0.5"
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: sigstore-prod-mysql-sa@oci-signer-service-dev.iam.gserviceaccount.com
      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "8091"
      securityContext:
        runAsNonRoot: true
        runAsUser: 65533
    mysql:
      enabled: false
      hostname: localhost
      auth:
        existingSecret: "trillian-mysql"
        username: "trillian"
      gcp:
        enabled: true
        instance: oci-signer-service-dev:us-central1:sigstore-prod-mysql-6553c6dc
        cloudsql:
          version: "1.29.0"
          resources:
            requests:
              memory: "0.5Gi"
              cpu: 0.1
          securityContext:
            runAsNonRoot: true
            runAsUser: 65533
    EOF
  ]
}
