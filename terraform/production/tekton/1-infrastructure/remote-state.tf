terraform {
  backend "gcs" {
    # Remote backend for tf state
    bucket = "oci-ci-service-dev-terraform-state"
    prefix = "/terraform/production/ci/"
  }
}
