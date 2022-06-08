# KMS Read Requests Above Quota

[Link to GCP Alert](https://console.cloud.google.com/monitoring/alerting/policies/5143684441194993633?project=oci-signer-service-dev)

##  Summary

This alert fires if KMS read requests are above quota for any KMS keys in the project.
The quota for KMS Read requests is 1500/min or 25/s.
This alert fires whenever read requests exceed 25/s.

From the [docs](https://cloud.google.com/kms/quotas): A read request is an operation that reads a Cloud KMS resource, such as a KeyRing, CryptoKey, CryptoKeyVersion, or Location.

## Links to Dashboards/Documentation
- [Quota usage for Cloud KMS](https://console.cloud.google.com/iam-admin/quotas?referrer=search&project=oci-signer-service-dev&pageState=(%22allQuotasTable%22:(%22f%22:%22%255B%257B_22k_22_3A_22Service_22_2C_22t_22_3A10_2C_22v_22_3A_22_5C_22Cloud%2520Key%2520Management%2520Service%2520%2528KMS%2529%2520API_5C_22_22_2C_22s_22_3Atrue_2C_22i_22_3A_22serviceTitle_22%257D%255D%22)))
- [GCP Docs for KMS Quota](https://cloud.google.com/kms/quotas)


## Possible Causes
This will depend on which KMS key is hitting the limit.
The current keys Sigstore uses in KMS are:
1. Rekor has a KMS key for signing rekor entries
1. There is a KMS key used for encrypting the GKE cluster
1. There will be a key for signing Fulcio certs once the intermediate cert is used

## Remediation
Consider increasing quota in the GCP UI:
1. Go to the [KMS Quota page](https://console.cloud.google.com/iam-admin/quotas?referrer=search&project=oci-signer-service-dev&pageState=(%22allQuotasTable%22:(%22f%22:%22%255B%257B_22k_22_3A_22Service_22_2C_22t_22_3A10_2C_22v_22_3A_22_5C_22Cloud%2520Key%2520Management%2520Service%2520%2528KMS%2529%2520API_5C_22_22_2C_22s_22_3Atrue_2C_22i_22_3A_22serviceTitle_22%257D%255D%22)))
1. Select "Quota=Read requests per minute"
1. Click "Edit Quotas"
1. Set the limit higher than the current 1,500/min

Once the higher quota is approved, you'll need to:
1. Update the `threshold_value` alert in [terraform](https://github.com/sigstore/public-good-instance/blob/5ebe11cd8903dcb07d4b81cadcf8eff8a5ffa86c/terraform/modules/monitoring/uptime/alerts.tf#L433) with the new limit
1. Update the details in this document with the new limit
