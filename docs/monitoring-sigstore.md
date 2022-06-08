# Monitoring Sigstore

All alerts are tracked in [GCP Monitoring](https://console.cloud.google.com/monitoring/alerting?referrer=search&project=oci-signer-service-dev).

## Deploying Monitoring
All monitoring for Sigstore is deployed via Terraform.
There are a few main components all of which are deployed in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf):
1. [Prometheus Helm Chart](../terraform/development/signer/3-sigstore-helm/monitoring.tf)
1. [monitoring terraform module](../terraform/development/modules/monitoring/)
1. [sigstore prober Helm Chart](https://github.com/sigstore/helm-charts/tree/main/charts/sigstore-prober)


### Prometheus
Prometheus is deployed via a Helm Chart in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf).
It runs in the GKE cluster in the `monitoring-system` namespace.
It runs under the `sigstore-prod-prometheus-sa@oci-signer-service-dev.iam.gserviceaccount.com` service account which has permissions to export to Stackdriver.

Prometheus is responsible for scraping metrics from:
* Rekor pods
* Fulcio pods
* Sigstore prober pod

and exporting this data to Stackdriver.
We can then access this data in GCP Monitoring and create alerts around it.
These alerts are configured in the [monitoring terraform module](../terraform/development/modules/monitoring/).

### Monitoring Terraform Module
This module contains all the alerts set up in GCP monitoring. 
It is responsible for creating alerts and assigning them a notification channel (this is the channel that will be alerted if an alert fires).

#### Notification Channels
Notificaton channels can be updated or added in the [GCP UI](https://console.cloud.google.com/monitoring/alerting/notifications?project=oci-signer-service-dev).

To start sending alerts to a new notification channel, change the value of `notification_channel_id` in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf). 
You can get the ID of a notification channel by running `gcloud alpha monitoring channels list --project oci-signer-service-dev`.

Then, deploy your changes as described in [Deploying Terraform via Github Actions](./infrastructure-sigstore.md#deploying-terraform-via-github-actions).

### Sigstore Prober Helm Chart

The sigstore prober Helm Chart is a public Helm Chart (https://github.com/sigstore/helm-charts/tree/main/charts/sigstore-prober).

The Chart installs the prober in GKE in the `sigstore-prober` namespace.
It polls all Rekor and Fulcio endpoints every 10 seconds to confirm these services are up and running.
The prober gathers the following data for each endpoint:
* Host (Rekor or Fulcio)
* Response Status Code
* Latency

Alerts are set up for the prober around each of these metrics.
These alerts can be found in [monitoring/prober](../terraform/development/modules/monitoring/prober/prober_alerts.tf).
