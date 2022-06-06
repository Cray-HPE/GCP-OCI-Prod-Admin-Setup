REGISTRY=gcr.io/oci-tekton-service-dev

.PHONY: spire-server-image
spire-server-image:
	docker build -t ${REGISTRY}/spire-server ./config/spire
	docker push ${REGISTRY}/spire-server