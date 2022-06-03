resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "monitoring-system"
  create_namespace = true
  atomic           = true
  version          = "15.8.1"

  values = [
    <<EOF
    kubeStateMetrics: true
    serviceAccounts:
      server:
        annotations:
          iam.gke.io/gcp-service-account: sigstore-prod-prometheus-sa@oci-signer-service-dev.iam.gserviceaccount.com 
    server:
      sidecarContainers:
        sidecar:
          image: gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:0.8.2
          imagePullPolicy: Always
          args:
          - "--prometheus.wal-directory=/data/wal"
          - "--stackdriver.kubernetes.location=us-central1-a"
          - "--stackdriver.kubernetes.cluster-name=sigstore-prod"
          - "--stackdriver.project-id=oci-signer-service-dev"
          ports:
          - name: sidecar
            containerPort: 9091
          volumeMounts:
          - name: storage-volume
            mountPath: /data
    EOF
  ]
}

// This helm chart deploys a prober to the GKE cluster
// The prober is responsible for polling all Rekor and Fulcio endpoints
// every 10 seconds. It reports latency, error code and endpoint.
// This data is exported to Stackdriver via Prometheus, which is then used to create
// alerts in GCP Monitoring.
resource "helm_release" "sigstore_prober" {
  name             = "sigstore-prober"
  repository       = "https://sigstore.github.io/helm-charts"
  chart            = "sigstore-prober"
  namespace        = "sigstore-prober"
  create_namespace = true
  atomic           = true
  version          = "0.0.1"
  values = [
    <<EOF
    namespace:
      create: false
    serviceAccount:
      create: true
      name: sigstore-prober
    spec:
      replicaCount: 1
      matchLabels:
        app: sigstore-prober
      args:
        fulcioHost: http://fulcio-server.fulcio-system.svc
        rekorHost: http://rekor-server.rekor-system.svc
        frequency: 10
    prometheus:
      port: 8080
    EOF
  ]

  depends_on = [
    helm_release.prometheus
  ]
}

// Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  project_id = var.project_id

  rekor_url               = "rekor-server.rekor-system.svc"
  fulcio_url              = "fulcio-server.fulcio-system.svc"
  notification_channel_id = "3677712677944843815"

  depends_on = [
    helm_release.sigstore_prober,
  ]
}
