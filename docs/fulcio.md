# Fulcio

Fulcio is Sigstore's Certificate Authority.
HPE Fulcio is set up to issue certs to various identity providers, including `sig-spire.algol60.net`.
The config for that is in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

Fulcio currently relies on GCP Certificate Authority to provide the root cert for issuing certificates.
In the future, this will be swapped for an HPE-provided intermediate certificate.

## Setting up Fulcio
Fulcio infrastructure (including the CA and relevant service accounts) is deployed in [1-infrastructure/sigstore.tf](../terraform/development/signer/1-infrastructure/sigstore.tf) as part of the Fulcio module.
The Fulcio application is set up via a Helm Chart and deployed with Terraform in [3-sigstore-helm/sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

## Updating Fulcio
The Fulcio Helm chart is deployed via Terraform in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

The Helm chart is publicly available at https://github.com/sigstore/helm-charts/tree/main/charts/fulcio.

To update the Helm Chart:
1. Change the desired version in `helm_release.fulcio` in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf)
1. Update any values in `helm_release.fulcio` in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf)
1. Merge these changes into `main`
1. Deploy the updated Terraform as described in [Deploying Terraform via Github Actions](./infrastructure-sigstore.md#deploying-terraform-via-github-actions)


# Debugging Fulcio

## Possible Issues
* [Fulcio pods are down](#fulcio-pods-are-down)
* [Fulcio config is incorrect](#fulcio-config-is-incorrect)


## Steps to Investigate
**Connect to the cluster by following instructions in [Connecting to GKE Cluster](./infrastructure-sigstore.md#connecting-to-the-gke-cluster).**

### Fulcio pods are down

Investigate the state of each Fulcio Pod and the Fulcio Deployment via the UI:
<!-- TODO: update links when we migrate from zonal to regional cluster -->
- [Fulcio pods](https://console.cloud.google.com/kubernetes/object/browser?project=oci-signer-service-dev&pageState=(%22savedViews%22:(%22i%22:%22eaad10f897e844faa3f42498183feede%22,%22c%22:%5B%22gke%2Fus-central1-a%2Fsigstore-prod%22%5D,%22n%22:%5B%22fulcio-system%22%5D)))
- [Fulcio Deployment](https://console.cloud.google.com/kubernetes/deployment/us-central1-a/sigstore-prod/fulcio-system/fulcio-server/overview?project=oci-signer-service-dev)

You can check the deployed YAML and the Logs from these UI links.

or alternatively via the CLI:

```
kubectl get po -n fulcio-system
kubectl describe deploy fulcio-server -n fulcio-system
kubectl logs deploy/fulcio-server -n fulcio-system
```

### Fulcio config is incorrect
Make sure Fulcio is hooked up to the correct GCP Certificate Authoritiy Service.

Check this in the UI:
<!-- TODO: update links when we migrate from zonal to regional cluster -->
- [Fulcio private-ca configmap](https://console.cloud.google.com/kubernetes/configmap/us-central1-a/sigstore-prod/fulcio-system/private-ca/details?project=oci-signer-service-dev)


or alternatively via CLI:

```
kubectl describe cm private-ca -n fulcio-system
```

### Support
Reach out to these Sigstore Slack chanels:
* [#general](https://sigstore.slack.com/archives/C01DGF0G8U9)
* [#fulcio](https://sigstore.slack.com/archives/C02K0T1LNPQ)
