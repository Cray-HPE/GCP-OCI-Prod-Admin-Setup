# Signer and Tekton Production steps

## High Level production

1. Copy over terraform from Development](../development)
2. Create new terraform state buckets
3. Rerun GitHub actions script for Production GCP project ./scripts/github-odic-setup.sh 
4. Upload the below variables 
5. Run Terraform for Signer
6. Run Terraform for Tekton 
7. Test signing 

## Signer Terraform 

Variables that need updating 

1-infrastructure 

- tunnel_accessor_sa
- attestation_bucket
- project_number
- project_id
- cluster_name
- database_encryption_key_name 

2-post-installation
- cluster_name
- project_id

3-sigstore-helm 
- cluster_name
- project_id

helm-chart-values
- GSA annotation on KSA iam.gke.io/gcp-service-accoun

## Tekton Terraform 

1-infrastructure
- network_name
- subnetwork_name
- cluster_name
- project_id
- env
- tunnel_accessor_sa
- database_encryption_key_name


2-post-installation
- cluster_name
- project_id

All of these are available in the Signer Project 
- REKOR_ADDRESS
- FULCIO_ADDRESS
- cert.pem
- ctlog-public.pem
- rekor.pub


Rekor: Rekor key pair is in GCP oci-signer-service-dev KMS
Chains: Requires fulcio and rekor URL endpoint
CTLog: CT Log public and private keys are in GCP secrets manager
Fulcio Cert: Available in Fulcio endpoint $FULCIO_ENDPOINT/api/v1/rootCert or in the GCP Secrets Manager

Spire Helm
- trustDomain
- fullyQualifiedTrustDomain
- email
- loadBalancerIP