# Rekor

Rekor is an immutable append-only transparency log used to store signatures, certificates, attestations and more.
The HPE instance of Rekor runs in a GKE Cluster and stores entries in a Cloud SQL MySQL database.
Rekor signs all entries using a key in GCP KMS.
This key is generated in terraform in the Rekor submodule of [sigstore.tf](../terraform/development/signer/1-infrastructure/sigstore.tf).

There is also a GCP Redis instance which Rekor stores data in to make it easier to index.

## Setting up Rekor
Rekor is set up via a Helm Chart and deployed with Terraform in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

## Updating Rekor
The Rekor Helm chart is deployed via Terraform in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf).

The Helm chart is publicly available at https://github.com/sigstore/helm-charts/tree/main/charts/rekor.

To update the Helm Chart:
1. Change the desired version in `helm_release.rekor` in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf)
1. Update any values in `helm_release.rekor` in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf)
1. Merge these changes into `main`
1. Deploy the updated Terraform as described in [Deploying Terraform via Github Actions](./infrastructure-sigstore.md#deploying-terraform-via-github-actions)

# Debugging Rekor

This doc walks through basic steps to debug Rekor.

## Possible Issues
* [Rekor service isn't running](#rekor-services-isnt-running)
* [Rekor Load Balancer service isn't running](#rekor-loadbalancer-service-isnt-running)


## Steps to Investigate

### Rekor Services Aren't Running

<!-- TODO: update links once we migrate from zonal to regional cluster -->
Observe Rekor Pods/Deployment in the GCP Console UI:
- [Rekor pods](https://console.cloud.google.com/kubernetes/object/browser?project=oci-signer-service-dev&pageState=(%22savedViews%22:(%22i%22:%22eaad10f897e844faa3f42498183feede%22,%22c%22:%5B%22gke%2Fus-central1-a%2Fsigstore-prod%22%5D,%22n%22:%5B%22rekor-system%22%5D)))
- [Rekor deployment](https://console.cloud.google.com/kubernetes/deployment/us-central1-a/sigstore-prod/rekor-system/rekor-server/overview?project=oci-signer-service-dev)

You can see the YAML deployment and logs from the UI.

Alternatively, check via CLI:


```
kubectl get po -n rekor-system
kubectl describe deploy -n rekor-system rekor-server
kubectl logs deploy/rekor-server -n rekor-system
```

### Rekor LoadBalancer Service isn't Running
Observe the service in the UI:
<!-- TODO: update links once we migrate from zonal to regional cluster -->
- [Rekor Service](https://console.cloud.google.com/kubernetes/service/us-central1-a/rekor-dev/rekor-system/rekor-server/overview?project=oci-signer-service-dev)

Click on the "external endpoint" and make sure it resolves to the Rekor homepage.
If it doesn't, then the Service `selector` may not mach the Deployment (see [k8s documentation](https://kubernetes.io/docs/concepts/services-networking/service/#service-resource)).

Otherwise, check via CLI:

```
# Get the load balancer IP
kubectl get svc rekor-server -n rekor-system --output json | jq '.status.loadBalancer.ingress[]  | .ip'

# Make sure you can curl the IP & get the Rekor homepage
curl $ip
```
If the `curl` command fails, then the Service `selector` may not mach the Deployment (see [k8s documentation](https://kubernetes.io/docs/concepts/services-networking/service/#service-resource)).


## Support
Reach out to these Sigstore Slack chanels:
* [#general](https://sigstore.slack.com/archives/C01DGF0G8U9)
* [#rekor](https://sigstore.slack.com/archives/C01CX4E2K70)
