# Trillian

[Trillian](https://github.com/google/trillian) is an implements Merkle trees, which both the Rekor transparency log and Fulcio's Certificate Transparency Log depend on.

Trillian runs in GKE cluster and trees are stored in the Cloud SQL database.
There is one tree for the HPE Rekor transparency log and another tree for the Certificate Transparency Log.

## Setting up Trillian
Trillian is set up via a Helm Chart and deployed with Terraform in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

## Updating the Trillian Helm Chart
The Trilian Helm chart is deployed via Terraform in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

The Helm chart is publicly available at https://github.com/sigstore/helm-charts/tree/main/charts/trillian.

To update the Helm Chart:
1. Change the desired version in `helm_release.trillian` in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf)
1. Update any values in `helm_release.trillian` in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf)
1. Merge these changes into `main`
1. Deploy the updated Terraform as described in [Deploying Terraform via Github Actions](./infrastructure-sigstore.md#deploying-terraform-via-github-actions)

## Debugging Trillian

### Possible Issues
1. Trillian pods are down
1. Trillian config connecting pods to CloudSQL backend isn't set up correctly
1. Trillian can't access CloudSQL backend
1. The CloudSQL backend isn't running


### Links to Dashboards
- [Cloud SQL Dashboards](https://console.cloud.google.com/monitoring/dashboards/resourceList/cloudsql_database?project=oci-signer-service-dev&timeDomain=1h)


### Steps to Investigate

**Connect to the cluster by following instructions in [Connecting to GKE Cluster](./infrastructure-sigstore.md#connecting-to-the-gke-cluster).**

1. Make sure Trillian pods are up and running

```
kubectl get po -n trillian-system
kubectl describe deploy/trillian-server -n trillian-system
kubectl logs deploy/trillian-server -n trillian-system
```

1. Make sure the ConfigMap telling Trillian which CloudSQL backend to use is set up correctly

```
kubectl describe configmap cloud-sql -n trillian-system
```

1. Make sure Trillian has the correct auth set up to connect to the CloudSQL DB

```
kubectl describe secret trillian-database -n trillian-system 
```

1. Make sure the CloudSQL DB exists and `STATUS=RUNNABLE`

```
export CLOUDSQL_DB_NAME= # the name can be found via `terraform output`
gcloud sql instances list --project oci-signer-service-dev
gcloud sql instances describe $CLOUDSQL_DB_NAME --project oci-signer-service-dev
```

### Support
Reach out to these Sigstore Slack chanels:
* [#general](https://sigstore.slack.com/archives/C01DGF0G8U9)
