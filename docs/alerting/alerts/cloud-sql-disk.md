# Cloud SQL Disk Utilization > 95%

[GCP Alert](https://console.cloud.google.com/monitoring/alerting/policies/14010437410628036263?project=oci-signer-service-dev)

## Summary

This alert fires when any database in the project exceeds 95% disk utilization.

Cloud SQL supports automatic storage increases with no downtime ([docs](https://cloud.google.com/blog/products/gcp/digging-in-on-cloud-sql-automatic-storage-increases)) so this alert should be automatically resolved by GCP.
Automatic increases will increase total storage by 5-10%.

If we consistently are over the 95% threshold, consider either increasing the threshold or manually increasing the disk size.

## Remediation

Increase the threshold from 95% by updating the `google_monitoring_alert_policy.cloud_sql_disk_utilization` alert in Terraform [here](../../../terraform/development/modules/monitoring/alerts.tf).
Then, deploy by applying the Terraform via the Github Action.

Or, you can allocate more disk space to the relevant Cloud SQL database either by:
1. Updating the Terraform module (first confirm this won't recreate the database)
2. Increasing manually via the GCP UI.

 **There will be a couple minutes of downtime.**

The Terraform code for this is in the [mysql](https://github.com/sigstore/scaffolding/tree/main/terraform/gcp/modules/mysql) module.

Terraform docs for [google_sql_database_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance).

## Relevant Threads
* [Slack thread](https://sigstore.slack.com/archives/C01P48SV8NQ/p1653990173164879)
