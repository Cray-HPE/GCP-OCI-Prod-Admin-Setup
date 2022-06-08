# Alerting Playbooks

This doc covers the alerts set up for the Sigstore project, and what to do if any of them fires.
All of these alerts are set up via the Terraform monitoring [module](../../terraform/development/modules/monitoring/).

- Cloud SQL Alerts
    * [Cloud SQL Database Memory Utilization > 90%](./alerts/cloud-sql-memory.md)
    * [Cloud Sql Disk Utilization > 95%](./alerts/cloud-sql-disk.md)
- Cloud KMS Alerts
    * [KMS Read Requests Above Quota](./alerts/kms-read-request.md)
    * [KMS Crypto Requests Rate Above Quota](./alerts/kms-crypto-request.md)
- Prober Alerts
    * [API Prober: Rekor API Endpoint Latency > 750 ms for 5 minutes](./alerts/read-endpoint-prober.md)
    * [API Prober: Fulcio API Endpoint Latency > 750 ms for 5 minutes](./alerts/read-endpoint-prober.md)
    * [API Prober: Latency Data Absent for 5 minutes: http://rekor-server.rekor-system.svc](./alerts/read-endpoint-prober.md)
    * [API Prober: Latency Data Absent for 5 minutes: http://fulcio-server.fulcio-system.svc](./alerts/read-endpoint-prober.md)
    * [API Prober: Error Codes are non-200](./alerts/read-endpoint-prober.md)
