# Secrets for the CT Log, including private and public key, are stored in GCP Secret Manager
# Use external-secrets which was set up in `2-post-installation` to store these in-cluster
# For access by the CT Log


resource "kubectl_manifest" "ctlog_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ctlog-system
  labels:
    name: ctlog-system
YAML
}

resource "kubectl_manifest" "ctlog_priv_key_external_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: ctlog-priv-key
  namespace: ctlog-system
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-backend
  target:
    name: ctlog-secret
    template:
      data:
        private: "{{ .privateKey | toString }}"  # <-- convert []byte to string
        public: "{{ .publicKey | toString }}"  # <-- convert []byte to string
        rootca: "{{ .rootCa | toString }}"  # <-- convert []byte to string
  data:
  - secretKey: privateKey
    remoteRef:
      key: ctlog-priv-key
  - secretKey: publicKey
    remoteRef:
      key: ctlog-public-key
  - secretKey: rootCa
    remoteRef:
      key: fulcio-root-ca
YAML

  depends_on = [
    kubectl_manifest.ctlog_namespace
  ]
}

resource "kubectl_manifest" "ctlog_config_external_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: ctlog-config
  namespace: ctlog-system
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-backend
  target:
    name: ctlog-config
    template:
      data:
        config: "{{ .config | toString }}"  # <-- convert []byte to string
  data:
  - secretKey: config
    remoteRef:
      key: ctlog-config
YAML

  depends_on = [
    kubectl_manifest.ctlog_namespace
  ]
}
