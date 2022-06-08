# SPIRE

SPIRE is set up in the `tekton-dev` GKE cluster in the `oci-tekton-service-dev` GCP project.
SPIRE OIDC is currently set up at the `https://sig-spire.algol60.net` domain.

## Custom SPIRE Setup
The majority of the SPIRE helm chart manifests were templatized from the [SPIRE Vault OIDC Tutorial](https://spiffe.io/docs/latest/keyless/vault/readme/), with the [k8s manifests here](https://github.com/spiffe/spire-tutorials/tree/main/k8s/oidc-vault).
There is one significant change -- instead of using the provided `gcr.io/spiffe-io/spire-server` SPIRE server image, HPE SPIRE uses a custom `spire-server` image.

This is because the SPIRE tutorial expects that SPIRE setup happens on a public cluster.
On a pubilc cluster, registering new entries with the SPIRE server can be done via `kubectl exec`.
Unfortunately, this is not possible on a private cluster with k8s version < v1.24, which is what HPE is running (1.24 is not yet supported by GKE.)

To get around this, we build a custom spire-server image which runs a custom bash script.
This custom bash script starts the SPIRE server **and** registers entries, and can be found at [start-server.sh](../config/spire/start-server.sh).

### Register a new Entry with the SPIRE Server
Currently, only Pods running in the `tekton-chains` namespace under the `tekton-chains-controller` service account can request an SVID from SPIRE, as that is the only entry registered in [start-server.sh](../config/spire/start-server.sh).
At the moment, only `tekton-chains` can request an identity token from SPIRE.

To register a new entry, follow these steps:
1. Add the new entry to [start-server.sh](../config/spire/start-server.sh)
1. Rebuild the custom spire-server image via `make spire-server-image`
1. Update the `spire-server` image to the new image in [values.yaml](../charts/spire/values.yaml)
1. Merge the change into the `Cray-HPE/GCP-OCI-Prod-Admin-Setup` Github repository `main` branch
1. Deploy the updated Terraform via the [Tekton Github Action](https://github.com/Cray-HPE/GCP-OCI-Prod-Admin-Setup/actions/workflows/provision-tekton.yaml)



## Verify SPIRE Setup
You can verify that SPIRE is set up properly by making sure the `https://sig-spire.algol60.net/keys` endpoint returns some keys:

```
curl https://sig-spire.algol60.net/keys

{
  "keys": [
    {
      "kty": "RSA",
      "kid": "ljkHu8BG1OX1vagKnvIdUmIL9RLHM2Tm",
      "n": "umhyO0Fb2GcYvz6qLQjwPmzfkPPpObVKQlB5GCl58yv2lI_2ILTebX9p3NLLR8R1Mb2pMj0LUKscJjwWPdh5Tzi1K-e3--zNJHk-hrAgl5QkO7iVZaWLu520hhVrqd6pKFrYHdbn-fQ0wk7QlpcCMSOwulvFJQnqUFw52QehiTXOGPPtp4OHNxjjYErG2G8bU7C6ap3DYaCXeH6XdZdBZgcDuHBJsf8U_IstPRx7lt3MbnzTetUeTZ4U8grzm42ybsjrwX3saRNK0stysFnxJxZXjOKVbUhIjKw2HrEnC7m1a66_ZO3T6f-vfzHbrlsy6jSON2HquK-zlhvJeM5GBQ",
      "e": "AQAB"
    },
    {
      "kty": "RSA",
      "kid": "iHd2eUjGbbCiXu5aid5gVlYFXjjKcUc4",
      "n": "0a6sY9_mSayiFLAaHtyHBosFJoUL67JYwkupcImPJOQFDACFXZ_UhZ1-Lq7CTT3z9i336-ObNS0QFzQmfmpQuUKOitVL4RUdiMY2kjnziEMNqjJllrAO5EoTll3cni0pHCbFdoZPabpfYKhUfH5ZrPDMKeWTzgVSbigtYU7q6b-SCcGLIaa-QF-hkzH-fhz2zBNXT80sfOVbTO_XO8hBAwUh9ots68noloZg4KN0YZlJsaIxUMq6rO7cl7hlKzkvz_F0H-oPk0EYUYfPFrM9wX6VnC3uP4ESTchZzUeZsfKBEumAjczlgPQcxolZmvor1usrbpNZAcJba7iU_4WB_Q",
      "e": "AQAB"
    },
    {
      "kty": "RSA",
      "kid": "NPZ37vifZv2R9dYrwimZk9Yzr1uRydAQ",
      "n": "sOIhzeCOokvZ0aVrVFg2-_QPgFqU7pWWZ523GujbLP_Or7xGid_1GJ4xKjI92_QGyHkUpTTbAU7Fox_RHBE1JDxdYsg8Tdx6t9g_-kDKITFzWCi2TlocmuRLJrWsX32QJNJEo03cu7j4J2EcmOaBq-RnhNN-z8cpxNToqeIs739h-AFJEQaDUeLxkvqFQXGfujjL-C8PD94SjMEdk9FWeqicm36AyMgKUmDTKK22t4_OEoKwjJCsYxh5VxQhg84JENbbnpkf01wAaP33nwKrmHiPZfcOwSwjCa8nrB7hhPFraSxAB7m-aOjyHrSrfWWGoOXEZogadfE-EHTv_lCVAQ",
      "e": "AQAB"
    },
    {
      "kty": "RSA",
      "kid": "wR2H8LWzS3HROWYwlVxzZIzNJpOA3S09",
      "n": "miPe-uganuqs_ztf23xTHkGwJob6hmN_sbjiN7gb6ToAZZGEcPeFfxR3h7QETUZmicgHXND65D95wjU2WGeuP-VvGgTAwz3UJdIzrvBThKAcuO0N5KFn70KZKi0MNqRhPfrK_jberVwcn_JVxiP0pQB0e25vBTazx2tc1botPpPdkqn4hmX-24U1dZa431CiBE2udKRKDkks-5xp9bagq4ngkCPW3qMx6hCzccIBVJj91tFFV-v7rZ3htfRGaH0et9l99OAiLozRiHZKGt6WqpTvS_r5eLnQ76B47MbLSTF5G36gwrAgWrBcsrcp8h9E_TRBtmaPKIFEZoDfv33OFw",
      "e": "AQAB"
    }
  ]
}
```

## Developing SPIRE

SPIRE is deployed as a Helm chart via Terraform in [spire.tf](../terraform/development/tekton/2-post-installation/spire.tf).
The Helm chart configuration lives in [charts/spire](../charts/spire/).

To make changes to the SPIRE config, you must:
1. Make required changes in the Helm chart templates in [charts/spire](../charts/spire/).
1. Update the Helm chart version in [Chart.yaml](../charts/spire/Chart.yaml)
1. Update the values of `SPIRE_HELM_CHART_VERSION` in [variables.tf](../terraform/development/tekton/2-post-installation/variables.tf)
1. Merge changes into `Cray-HPE/GCP-OCI-Prod-Admin-Setup` Github `main` branch
1. Deploy the updated Terraform via the [Tekton Github Action](https://github.com/Cray-HPE/GCP-OCI-Prod-Admin-Setup/actions/workflows/provision-tekton.yaml)

## Requesting a Cert from Fulcio with a SPIRE Identity
The Fulcio config in [sigstore.tf](../terraform/development/signer/3-sigstore-helm/sigstore.tf) has an entry for `sig-spire.algol60.net`.
This means that HPE Fulcio will accept identity tokens from the SPIRE OIDC provider at `sig-spire.algol60.net`.
If this entry is removed from the Fulcio config, this identity will no longer be accepted.
