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


resource "helm_release" "fulcio" {
  name             = "fulcio"
  repository       = "https://sigstore.github.io/helm-charts"
  chart            = "fulcio"
  namespace        = "fulcio-system"
  create_namespace = true
  atomic           = true
  version          = "0.2.11"

  depends_on = [
    helm_release.trillian
  ]

  values = [
    <<EOF
    enabled: true
    namespace:
      name: fulcio-system
      create: false
    forceNamespace: fulcio-system
    createcerts:
      fullnameOverride: fulcio-createcerts
    ctlog:
      enabled: false
    config:
      contents: {
        # TODO: Figure out which OIDC issuers, if any, are allowed
        "OIDCIssuers": {
          "https://accounts.google.com": {
            "IssuerURL": "https://accounts.google.com",
            "ClientID": "sigstore",
            "Type": "email"
          },
          "https://oauth2.sigstore.dev/auth": {
            "IssuerURL": "https://oauth2.sigstore.dev/auth",
            "ClientID": "sigstore",
            "Type": "email",
            "IssuerClaim": "$.federated_claims.connector_id"
          },
          "https://token.actions.githubusercontent.com": {
            "IssuerURL": "https://token.actions.githubusercontent.com",
            "ClientID": "sigstore",
            "Type": "github-workflow"
          }
        },
        "MetaIssuers": {
          "https://container.googleapis.com/v1/projects/*/locations/*/clusters/*": {
            "ClientID": "sigstore",
            "Type": "kubernetes"
          },
          "https://oidc.eks.*.amazonaws.com/id/*": {
            "ClientID": "sigstore",
            "Type": "kubernetes"
          },
          "https://oidc.prod-aks.azure.com/*": {
            "ClientID": "sigstore",
            "Type": "kubernetes"
          }
        }
      }
    server:
      fullnameOverride: fulcio-server
      replicaCount: 3
      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "2112"
      ingress:
        //TODO (priyawadhwa): Update when we have ingress for fulcio
        enabled: false
      args:
        # TODO: Update once we have an intermediate cert
        certificateAuthority: googleca
        gcp_private_ca_parent: projects/oci-signer-service-dev/locations/us-central1/caPools/sigstore-ca
      resources:
        requests:
          memory: "1G"
          cpu: ".5"
      serviceAccount:
        annotations:
          iam.gke.io/gcp-service-account: sigstore-prod-fulcio-sa@oci-signer-service-dev.iam.gserviceaccount.com
      securityContext:
        runAsNonRoot: true
        runAsUser: 65533
      # TODO: Remove once we aren't using a LoadBalancer
      service:
        type: LoadBalancer
        ports:
          - name: 5555-tcp
            port: 80
            protocol: TCP
            targetPort: 5555
          - name: 2112-tcp
            port: 2112
            protocol: TCP
            targetPort: 2112
    EOF
  ]
}

resource "helm_release" "ctlog" {
  name             = "ctlog"
  repository       = "https://sigstore.github.io/helm-charts"
  chart            = "ctlog"
  namespace        = "ctlog-system"
  create_namespace = true
  atomic           = true
  version          = "0.2.11"

  depends_on = [
    helm_release.fulcio
  ]

  values = [
    <<EOF
    enabled: true
    namespace:
      name: ctlog-system
      create: false
    forceNamespace: ctlog-system
    fullnameOverride: ctlog
    createcerts:
      fullnameOverride: ctlog-createcerts
    createtree:
      fullnameOverride: ctlog-createtree
      securityContext:
        runAsNonRoot: true
        runAsUser: 65533
    createctconfig:
      fullnameOverride: ctlog-createctconfig
      fulcioURL: http://fulcio-server.fulcio-system.svc
      securityContext:
        runAsNonRoot: true
        runAsUser: 65533
    server:
      replicaCount: 3
      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "6963"
      ingress:
        # TODO: (priyawadhwa) enable ingress
        enabled: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 65533
      resources:
        requests:
          memory: "1G"
          cpu: "0.5"
    trillian:
      logServer:
        portRPC: 8090
        portHTTP: 8091
    EOF
  ]
}
