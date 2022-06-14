# Terraform Fulcio

This terraform directory contains the terraform required to set up a production-quality instance of Fulcio.
The terraform is split up into two parts:
* `1-infrastructure`
* `2-post-installation`
* `3-sigstore-helm`

The first,`1-infrastructure`, step sets up most required infrastructure for Fulcio, including creating a private GKE cluster and a 
Bastion used to access the GKE cluster. The second step installs secrets into the GKE cluster itself.

To gain access to the cluster, the host running the workflow (in our case, GitHub Actions) needs to connect to the private cluster via the bastion.
For this reason, we split up the installation into two parts. 
The first part only requires access to the GCP project, and the second part requires access to the bastion to install secrets directly into the cluster.

`2-post-installion` installs the external secrets store, so we can store secrets in GCP secrets manager 

The last step `3-sigstore-helm`, installs the sigstore pieces via the helm chart. 
