# Cloud SQL Database Memory Utilization > 90%

[GCP Alert](https://console.cloud.google.com/monitoring/alerting/policies/14010437410628036216?project=oci-signer-service-dev)

## Summary

This alert fires when any database in the project exceeds 90% memory utilization.

## Remediation

Allocate more memory to the relevant Cloud SQL database by updating the value in Terraform.
The Terraform code for this is in the mysql module in [sigstore.tf](../../../terraform/development/signer/1-infrastructure/sigstore.tf).

Terraform config for [google_sql_database_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance).
