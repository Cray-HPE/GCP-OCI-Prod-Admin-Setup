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
