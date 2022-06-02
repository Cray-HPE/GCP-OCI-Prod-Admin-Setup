FROM gcr.io/spiffe-io/spire-server@sha256:fbf64ed15687c1a5141b52d46d2b9082837fd286af16fbf670d155d0ec5e3dd3
COPY start-server.sh /start-server.sh
ENTRYPOINT ["/usr/bin/dumb-init", "/start-server.sh"]
