resource "helm_release" "tekton_pipelines" {
  name             = "tekton-pipelines"
  chart            = "tekton-pipelines"
  repository       = var.TK_PIPELINE_HELM_REPO
  version          = var.TK_PIPELINE_HELM_CHART_VERSION
  namespace        = var.TK_PIPELINE_NAMESPACE
  create_namespace = true
  recreate_pods    = true
  force_update     = true
  cleanup_on_fail  = false
  timeout          = 60
  set {
    name  = "featureFlags.disable-affinity-assistant"
    value = "true"
  }
}

resource "helm_release" "tekton_dashboard" {
  depends_on       = [helm_release.tekton_pipelines]
  name             = "tekton-dashboard"
  chart            = "tekton-dashboard"
  repository       = var.TK_DASHBOARD_HELM_REPO
  version          = var.TK_DASHBOARD_HELM_CHART_VERSION
  namespace        = var.TK_PIPELINE_NAMESPACE
  create_namespace = false
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = true
}

resource "helm_release" "tekton_chains" {
  depends_on       = [helm_release.tekton_pipelines]
  name             = "tekton-chains"
  chart            = "tekton-chains"
  repository       = var.TK_CHAINS_HELM_REPO
  version          = var.TK_CHAINS_HELM_CHART_VERSION
  namespace        = var.TK_CHAINS_NAMESPACE
  create_namespace = true
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = true
  set {
    name  = "tenantconfig.artifacts\\.oci\\.format"
    value = "simplesigning"
  }
  set {
    name  = "tenantconfig.artifacts\\.oci\\.storage"
    value = "oci"
  }
  set {
    name  = "tenantconfig.artifacts\\.taskrun\\.format"
    value = "in-toto"
  }
  set {
    name  = "tenantconfig.signers\\.x509\\.fulcio\\.address" # Connect chains to fulcio service
    value = var.FULCIO_ADDRESS
  }
  set {
    name  = "tenantconfig.signers\\.x509\\.fulcio\\.enabled"
    value = "true"
  }
  set {
    name  = "tenantconfig.transparency\\.enabled"
    value = "true"
  }
  set {
    name  = "tenantconfig.transparency\\.url" # Connect chains to rekor service
    value = var.REKOR_ADDRESS
  }
}

resource "kubernetes_secret" "ctlog-public-key" {
  metadata {
    name      = "ctlog-public-key"
    namespace = "default"
  }
  data = {
    public = file("${path.module}/ctlog-public.pem")
  }
}

resource "kubernetes_secret" "SIGSTORE_ROOT_FILE" {
  metadata {
    name      = "fulcio-cert"
    namespace = "default"
  }
  data = {
    public = file("${path.module}/cert.pem")
  }
}

resource "kubernetes_service_account" "tekton" {
  metadata {
    name =  var.tekton_sa_name
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.tekton_gsa.email
    }
  }
}

# Services account for GKE workloads, fulcio etc.
resource "google_service_account" "tekton_gsa" {
  account_id   = var.tekton_sa_name
  display_name = "GKE Service Account Workload user for Tekton"
  project      = var.project_id
}

# Allow the workload KSA to assume GSA
resource "google_service_account_iam_member" "workload_account_iam" {
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.tekton_working_namespace}/${var.tekton_sa_name}]"
  service_account_id = google_service_account.tekton_gsa.name
  depends_on         = [google_service_account.tekton_gsa]
}

# GSA Access to storage for repo
resource "google_project_iam_member" "storage_admin_member" {
  project    = var.project_id
  role       = "roles/storage.admin"
  member     = "serviceAccount:${google_service_account.tekton_gsa.email}"
  depends_on = [google_service_account.tekton_gsa]
}