module "external_secrets" {
  source = "git::https://github.com/sigstore/scaffolding.git//terraform/gcp/modules/external_secrets"

  external_secrets_chart_version          = var.external_secrets_chart_version
  external_secrets_chart_values_yaml_path = "../helm-charts-values/external-secrets.yaml"
  project_id                              = var.project_id
}


resource "kubectl_manifest" "spire_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: spire
  labels:
    name: spire
YAML

  depends_on = [
    module.external_secrets
  ]
}

# TODO: Fix (priyawadhwa@)
# resource "kubectl_manifest" "spire_external_secret" {
#   yaml_body = <<YAML
# apiVersion: external-secrets.io/v1alpha1
# kind: ExternalSecret
# metadata:
#   name: spire-dockerconfig
#   namespace: spire
# spec:
#   secretStoreRef:
#     kind: ClusterSecretStore
#     name: gcp-backend
#   target:
#     name: spire-image-pull-secret-creds
#     template:
#       type: kubernetes.io/dockerconfigjson
#       data:
#         .dockerconfigjson: "{{ .spire-dockerconfig | toString }}"
#   data:
#   - secretKey: spire-dockerconfig
#     remoteRef:
#       key: spire-dockerconfig
# YAML

#   depends_on = [
#     kubectl_manifest.spire_namespace
#   ]
# }


resource "helm_release" "spire" {
  name             = "spire"
  chart            = var.SPIRE_CHART_PATH
  version          = var.SPIRE_HELM_CHART_VERSION
  namespace        = var.SPIRE_NAMESPACE
  create_namespace = false
  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = false
  timeout          = 60
  set {
    name  = "trustDomain"
    value = "sig-spire.algol60.net"
  }

  set {
    name  = "fullyQualifiedTrustDomain"
    value = "https://sig-spire.algol60.net"
  }

  set {
    name  = "email"
    value = "pwadhwa@algol60.net"
  }

  set {
    name  = "loadBalancerIP"
    value = "35.232.144.34"
  }
}
