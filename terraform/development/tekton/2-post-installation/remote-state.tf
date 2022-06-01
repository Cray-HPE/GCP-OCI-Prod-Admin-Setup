terraform {
  backend "gcs" {
    # Remote backend for tf state
    bucket = "oci-ci-service-dev-terraform-state"
    prefix = "/terraform/dev/ci/2-post-installation/"
  }
}
