# Scripts

The `github-oidc-setup.sh` is a one-time script that needs to be run on a GCP project to allow Github Actions permission to deploy terraform infrastructure to GCP.
The script generates a workload identity pool, workload identity provider and service account for Github Actions.
It then assigns the service account the `roles/iam.workloadIdentityUser` role.

It follows this [Google Blog Post](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)
for setting up keyless authentication from Github Actions to GCP.
