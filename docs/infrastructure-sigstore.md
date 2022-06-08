# Sigstore Infrastructure

This doc gives an overview of the sigstore infrastructure set up in the `oci-signer-service-dev` GCP project.


## Google Cloud Platform Services

This section covers the GCP services required for Sigstore to run.
All of these have been codified via terraform.
The terraform is available [here](../terraform/development/signer/).

The Sigstore instance currently runs on Google Cloud Platform in the `oci-signer-service-dev` GCP project.
It requires the following services:

**Google Kubernetes Engine** -- [link](https://console.cloud.google.com/kubernetes/list/overview?referrer=search&project=oci-signer-service-dev)

There is currently one private zonal cluster set up in the `us-central1-a` region in which Sigstore services all run.

<!-- TODO: Add in monitoring.md (priyawadhwa@) -->
Additionally, a prober runs in the cluster (more details in monitoring.md).

**Google Compute Engine** -- [link](https://console.cloud.google.com/compute/instances?referrer=search&project=oci-signer-service-dev)

A bastion is set up in Google Compute Engine to access the private GKE cluster when needed for development or debugging.
For details on accessing the cluster, see [Connecting to the GKE cluster](#connecting-to-the-gke-cluster).

**Cloud SQL** -- [link](https://console.cloud.google.com/sql/instances?referrer=search&project=oci-signer-service-dev)

There is one Cloud SQL MySQL database set up. 
This database holds all entries for the Rekor transparency log and the Certificate Transparency log.

**GCP Secret Manager** -- [link](https://console.cloud.google.com/security/secret-manager?referrer=search&project=oci-signer-service-dev)

The GCP secret manager contains secrets required for setting up Sigstore including:
* The CT Log public and private key pair
* The password for accessing the Cloud SQL MySQL database
* The Trillian Tree ID for the Rekor transparency log
* The Trillian Tree ID for the CT Log

**Cloud KMS** -- [link](https://console.cloud.google.com/security/kms/keyrings?referrer=search&project=oci-signer-service-dev)

Cloud KMS contains the following required signing keys:
* Signing key for the Rekor transparency log (`rekor-keying`)
* Signing key for encrypting the GKE cluster database (`gke-encryption`)
* Signing key imported from internal HPE for the Fulcio intermediate cert 

**Google Cloud Monitoring**

Used for monitoring and alerting on the Sigstore infrastrcture.
See monitoring.md for more details.

## Networking

All GCP infrastructure including the GKE cluster and the Cloud SQL database are running in a private network [sigstore-prod-network](https://console.cloud.google.com/networking/networks/details/sigstore-prod-network?q=search&referrer=search&project=oci-signer-service-dev&pageTab=SUBNETS).
[Cloud NAT](https://console.cloud.google.com/net-services/nat/details/us-central1/sigstore-prod-cloud-router/sigstore-prod-cloud-nat?project=oci-signer-service-dev&tab=details) is set up so that public images can be pulled within the cluster.


## Terraform

The base infrastructure is codified in Terraform.
Most components of the stack are available as public Terraform modules at [github.com/sigstore/scaffolding/terraform/gcp/modules](https://github.com/sigstore/scaffolding/tree/main/terraform/gcp/modules).
The `gke_cluster` and `monitoring` modules were copied into the local [modules](../terraform/development/modules/) directory from the public sigstore repository so that custom changes could be made.
For `gke_cluster` the custom change was adding in database encryption.
For `monitoring` the custom change was removing alerts that don't apply to the HPE use case (e.g. Dex alerts).

All terraform for Sigstore is located in the [terraform signer directory](../terraform/development/signer/).
This directory has three phases:

* [1-infrastructure](#infrastructure-phase)
* [2-post-installation](#post-installation-phase)
* [3-sigstore-helm](#sigstore-helm)

The infrastructure phase requires access to the GCP project to set up underlying GCP resources, including the cluster and bastion.
The post-installation and sigstore-helm phases require access to the private cluster via the bastion, so they must be run separately once the cluster and bastion are set up.

### Infrastructure Phase

This phase focuses on setting up all the underlying GCP resources.

* Private Network
* Bastion instance
  * for communicating to resources on Private Network
* GKE Cluster
* CloudSQL MySQL
* Rekor resources
  * Redis
  * Attestation Bucket
  * KMS Keys
* Fulcio resources

This phase requires access to the GCP project.

### Post-Installation Phase

This phase focus on the bootstrapping of Kubernetes resources.
The separation is needed as it requires all the underlying infrastructure resources to be running and that it needs the information from the previous phase to access the Kubernetes cluster via the bastion tunnel.

This phase is used to install the Helm chart for External Secrets via Terraform in [external-secrets.tf](../terraform/development/signer/2-post-installation/apps.tf).
The values for the Helm charts can be found in [external-secrets.yaml](../terraform/development/signer/helm-charts-values/external-secrets.yaml).

* External Secrets
  * Used to sync secrets from GCP Secrets to Kubernetes Secrets


### Sigstore Helm
This phase focuses on installing Sigstore and on installing [monitoring](../terraform/development/modules/monitoring/).

Helm charts for Sigstore can be found in the public https://github.com/sigstore/helm-charts repository.
Helm Charts for Sigstore services are installed via Terraform in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf):
* trillian
* fulcio
* rekor
* ctlog

Helm charts for monitoring are installed via Terraform in [monitoring.tf](../terraform/development/signer/3-sigstore-helm/monitoring.tf).
* prometheus
* sigstore_prober (used for monitoring Sigstore services)


### Deploying Terraform via Github Actions

Terraform is deployed via a Github Action in the `Cray-HPE/GCP-OCI-Prod-Admin-Setup` Github project.

The Github Action can be found here: https://github.com/Cray-HPE/GCP-OCI-Prod-Admin-Setup/actions/workflows/provision-sigstore.yaml

There are two modes for running this workflow:
* `plan` 
* `apply`

Selecting `plan` will print out intended changes to infrastructure Terraform will make, but will not apply them.
Selecting `apply` will apply the changes to the infrastrcutre.

**Always run `plan` and ensure the changes are acceptable before running `apply`.**

## Github Actions Authentication to GCP
Github Actions is able to access the GCP project by running under the `github-actions@oci-signer-service-dev.iam.gserviceaccount.com` service account in the `oci-signer-service-dev` GCP project.
This service account has all required permissions to create the required Terraform infrastructure.

The authentication between GCP and Github was set up by following this [blog post](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions).
For convenience, there is a script [github-oidc-setup.sh](../scripts/github-oidc-setup.sh) that can be run to set up the Github identity pool in GCP again.
This script also creates the `github-actions@oci-signer-service-dev.iam.gserviceaccount.com` service account if it doesn't exist and applies all required IAM roles to it.

## Connecting to the GKE Cluster

For increased security, the Sigstore GKE cluster is a private cluster running in a private network.
To access this cluster, you must create an SSH tunnel via the bastion instance.

In one terminal tab, run the following to create the SSH tunnel to the bastion instance:

```
gcloud compute ssh --zone us-central1-a bastion-349a61c7 --tunnel-through-iap --project oci-signer-service-dev -- -N -D 8118
```

In another terminal tab, get credentials for the cluster:

```
gcloud container clusters get-credentials --project oci-signer-service-dev --region us-central1-a --internal-ip sigstore-prod
```

With the above SSH tunnel, one can access the cluster with kubectl after setting the environment variable `HTTPS_PROXY=socks5://localhost:8118`.

For example, get all namespaces in the cluster by running:
```
HTTPS_PROXY=socks5://localhost:8118 kubectl get namespaces
```


**NOTE** The above commands for the bastion name may change. If the above commands don't work, you can get the most recent state by running the following:

```
cd terraform/development/signer/1-infrastructure
terraform output # This should print out the most up-to-date commands
```
