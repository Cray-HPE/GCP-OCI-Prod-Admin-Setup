# Prometheus


## Setting up Prometheus
Prometheus is set up via a Helm Chart and deployed with Terraform in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf).

Prometheus runs under the `sigstore-prod-prometheus-sa@oci-signer-service-dev.iam.gserviceaccount.com` service account which requires permissions to export Metrics to Stackdriver.
These metrics are used to create alerts in GCP Monitoring.
This service account is configured in [service-accounts.tf](../terraform/development/modules/gke_cluster/service_accounts.tf).

## Updating the Prometheus Helm Chart
The Prometheus Helm chart is deployed via Terraform in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf).

The Helm chart is publicly available at https://prometheus-community.github.io/helm-charts.

To update the Prometheus Helm Chart:
1. Change the desired version in `helm_release.prometheus` in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf)
1. Update any values in `helm_release.Prometheus` in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf)
1. Merge these changes into `main`
1. Deploy the updated Terraform as described in [Deploying Terraform via Github Actions](./infrastructure-sigstore.md#deploying-terraform-via-github-actions)


# Debugging Prometheus

## Possible Issues
* [Services (Rekor/Fulcio/Sigstore Prober) aren't properly configured for Prometheus to scrape metrics](#services-arent-properly-configured)
* [Prometheus is down](#prometheus-is-down)
* [Prometheus SA doesn't have the correct permissions](#prometheus-sa-doesnt-have-the-correct-permissions)

## Steps to Investigate

### Services Aren't Properly Configured

The Sigstore prober, Rekor and Fulcio **Pods** (_not just Deployments_) need to have all of the following annotations for Prometheus to correctly scrape metrics:

```
prometheus.io/scrape: "true"
prometheus.io/path: /metrics
prometheus.io/port: "2112"
```

Inspect Pods to make sure these annotations exist:
<!-- TODO: update links when we migrate to the new regional cluster -->
- [Rekor & Fulcio Pods](https://console.cloud.google.com/kubernetes/object/browser?project=oci-signer-service-dev&pageState=(%22savedViews%22:(%22i%22:%22eaad10f897e844faa3f42498183feede%22,%22c%22:%5B%22gke%2Fus-central1-a%2Fsigstore-prod%22%5D,%22n%22:%5B%22fulcio-system%22,%22monitoring-system%22,%22rekor-system%22%5D)))

or alternatively via CLI:

```
kubectl get pod PODAME -n NAMESPACE --output json | jq -r .metadata.annotations

# should output
{
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "2112",
  "prometheus.io/scrape": "true"
}
```

If these annotations don't exist, you'll have to add them to the Helm deployment in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf) for the relevant services and redeploy via the Github Action.


### Prometheus is Down

Prometheus is installed via Helm chart in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf).

<!-- TODO: update links when we migrate to the new regional cluster -->
To check the state of Prometheus pods, check the UI:
- [Prometheus Pods](https://console.cloud.google.com/kubernetes/object/browser?project=oci-signer-service-dev&pageState=(%22savedViews%22:(%22i%22:%22eaad10f897e844faa3f42498183feede%22,%22c%22:%5B%22gke%2Fus-central1-a%2Fsigstore-prod%22%5D,%22n%22:%5B%monitoring-system%22%5D)))
- Deployments:
  * [prometheus-server](https://console.cloud.google.com/kubernetes/deployment/us-central1-a/sigstore-prod/monitoring-system/prometheus-server/overview?project=oci-signer-service-dev)
  * [prometheus-alertmanager](https://console.cloud.google.com/kubernetes/deployment/us-central1-a/sigstore-prod/monitoring-system/prometheus-alertmanager/overview?project=oci-signer-service-dev)
  * [prometheus-kube-state-metrics](https://console.cloud.google.com/kubernetes/deployment/us-central1-a/sigstore-prod/monitoring-system/prometheus-kube-state-metrics/overview?project=oci-signer-service-dev)
  * [prometheus-pushgateway](https://console.cloud.google.com/kubernetes/deployment/us-central1-a/sigstore-prod/monitoring-system/prometheus-pushgateway/overview?project=oci-signer-service-dev)

You can observe the logs and deployed YAML from the links to the Deployments above.

or check via CLI:

```
# Check the state of the pods
kubectl get po -n monitoring-system

# Check the state of the deployments
kubectl get deploy -n monitoring-system

# Check logs for the deployments
kubectl logs deploy/prometheus-server -n monitoring-system
kubectl logs deploy/prometheus-alertmanager -n monitoring-system
kubectl logs deploy/prometheus-kube-state-metrics -n monitoring-system
kubectl logs deploy/ prometheus-pushgateway -n monitoring-system
```

### Prometheus SA doesn't have the correct permissions

The Prometheus Kubernetes service account needs to have Workload Identity enabled and map to the GCP Prometheus Service Account.
This is set up in [service-accounts.tf](../terraform/development/modules/gke_cluster/service_accounts.tf).

Make sure the `prometheus-server` Service Account is mapped to the correct GCP Service Account via annotation:

<!-- TODO: update links when we migrate to the new regional cluster -->
You can check via the UI:
- [Prometheus Service Account](https://console.cloud.google.com/kubernetes/object/core/serviceaccounts/us-central1-a/sigstore-prod/monitoring-system/prometheus-server?apiVersion=v1&project=oci-signer-service-dev)

or via CLI:

```
kubectl get serviceaccount prometheus-server -n monitoring-system --output json | jq -r .metadata.annotations

# should print out something like:
{
  "iam.gke.io/gcp-service-account": "sigstore-staging-prometheus-sa@oci-signer-service-dev.iam.gserviceaccount.com"
}
```

If this annotation doesn't exist, you'll need to add it to the service account template in Helm and redeploy.


Navigate to the project [IAM page](https://console.cloud.google.com/iam-admin/iam?referrer=search&project=oci-signer-service-dev),
and make sure the GCP Service Account in the annotation exists and has the following permissions:
* `roles/monitoring.metricWriter`
* `roles/iam.workloadIdentityUser`
