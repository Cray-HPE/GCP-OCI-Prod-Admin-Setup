# API Read Request Prober

[Link To Fulcio Alert](https://console.cloud.google.com/monitoring/alerting/policies/17916706019676330864?project=oci-signer-service-dev)
[Link To Rekor Alert](https://console.cloud.google.com/monitoring/alerting/policies/2572294258888044289?project=oci-signer-service-dev)

## Summary

The API Read request prober is a prober that runs in Kubernetes.
It pings all Read endpoints for Fulcio and Rekor every 10 seconds.
It keeps track of latency, response status code, and endpoint, and exports these metrics via Prometheus.
Prometheus scrapes these metrics from the `sigstore-prober` Deployment and uploads them to GCP Cloud Monitoring.

Prober alerts will fire in the following scenarios:
* If latency is >750ms for any single endpoint for more than 5 minutes
* Prober data is missing for more than 5 minutes
* Any endpoint has been returning non-200 error codes for more than 5 minutes

These alerts help us track SLOs for Rekor and Fucio API endpoints.

## Steps to Investigate

### Latency >750 ms for any single endpoint

If latency for a single endpoint is >750 ms, you can take these steps to investigate:
* Investigate the health of the Rekor deployment by following [rekor.md](../../rekor.md)

Known issues:
* [Rekor open issue](https://github.com/sigstore/rekor/issues/741): search endpoints for Rekor often report high latency, something like implementing pagination or improving searching the Redis DB would be a potential solution

### Data is missing for more than 5 minutes

There are a few potential reasons for this:

**The `sigstore-prober` Deployment is down**

Check the logs for the `sigstore-prober` Deployment in the `sigstore-prober` namespace.

If there's a bug in the prober, you'll have to take these steps to fix it:
1. Fix the prober code in [sigstore/scaffolding](https://github.com/sigstore/scaffolding/blob/main/cmd/prober/prober.go)
1. Release a new prober image by running the [Release](https://github.com/sigstore/scaffolding/actions/workflows/release.yaml) Github Action in `sigstore/scaffolding`
1. Update the sigstore-prober [helm chart](https://github.com/sigstore/helm-charts/tree/main/charts/sigstore-prober) with a new version and the new image. Once the PR is merged the helm chart should be released automatically.
1. Update the [Argo config](../../../argocd/utilities/templates/prober.yaml) with the new Helm chart version. Argo should automatically redeploy.

Since the above process can take some time depending on how long it takes to get PRs approved, you can temporarily skip straight to Step 3
by building the image prober yourself and deploying it. 

You can do this by:

1. Making the appropriate changes to the sigstore-prober code
1. Update `KO_DOCKER_REPO` in the `sigstore/scaffolding` [Makefile](https://github.com/sigstore/scaffolding/blob/main/Makefile) to your own public GCP repo
1. Run `make ko-resolve` to build and push the latest prober image (this will also build and push the other images in the repo)
1. Update `spec.image` in the `helm.values` section of [prober.yaml](../../../argocd/utilities/templates/prober.yaml)

**Metrics collection isn't happening in the Deployment**

Make sure metrics are available at the metrics endpoint for `sigstore-prober`.
Since port-forwarding currently isn't availble over the socks proxy, the easiest way to do this is to verify locally.

Run the prober locally:

```
# This is the sigstore/scaffolding Github repo
cd scaffolding

# For production use : `-rekor-url https://rekor.sigstore.dev -fulcio-url https://fulcio.sigstore.dev`
# For staging use: `-rekor-url https://rekor.sigstage.dev -fulcio-url https://fulcio.sigstage.dev`
go run ./cmd/prober -rekor-url REKOR_URL -fulcio-url FULICO_URL
```

and check the endpoint:

```
curl localhost:8080/metrics
```

Prometheus metrics should be printed out. 
If there aren't any, there's likely a bug in the prober code.
Debug the code and follow the instructions in the previous step to deploy the fix.

**Prometheus isn't scraping metrics**

Run through [prometheus.md](../../../prometheus.md) to make sure Prometheus is running and has the correct IAM permissions with Workload Identity to export metrics to Google Cloud Monitoring.

### Any endpoint has been returning non-200 error codes for more than 5 minutes
If this is the case, you can take these steps to investigate:
* Investigate the health of the Rekor deployment by following [rekor.md](../rekor.md)
* Search for errors in the Rekor deployment logs

## Support
Reach out to these Sigstore Slack chanels:
* [#general](https://sigstore.slack.com/archives/C01DGF0G8U9)
* [#rekor](https://sigstore.slack.com/archives/C01CX4E2K70)
