terraform {
  backend "gcs" {
    # Remote backend for tf state
    bucket = "oci-signer-service-dev-terraform-state"
    prefix = "/terraform/production/2-post-installation/"
  }
}
