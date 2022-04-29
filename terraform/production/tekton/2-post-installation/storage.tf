resource "kubernetes_manifest" "regional_sc" {
  manifest = {
    "kind" = "StorageClass"
    "apiVersion" = "storage.k8s.io/v1"
    "metadata" = {
      "name" : "regionalpd-storageclass"
    }
    "provisioner" = "pd.csi.storage.gke.io"
    "parameters" = {
      "type"             = "pd-standard"
      "replication-type" = "regional-pd"
    }
    "volumeBindingMode" = "WaitForFirstConsumer"
  }
}