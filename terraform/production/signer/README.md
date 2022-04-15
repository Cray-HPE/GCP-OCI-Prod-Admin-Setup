# Terraform Fulcio

This terraform directory contains the terraform required to set up a production-quality instance of Fulcio.
The terraform is split up into two parts:
* `1-infrastructure`
* `2-post-installation`

The first step sets up most required infrastructure for Fulcio, including creating a private GKE cluster and a Bastion used to access the GKE cluster.
The second step installs secrets into the GKE cluster itself.

To gain access to the cluster, the host running the workflow (in our case, GitHub Actions) needs to connect to the private cluster via the bastion.
For this reason, we split up the installation into two parts. 
The first part only requires access to the GCP project, and the second part requires access to the bastion to install secrets directly into the cluster.
