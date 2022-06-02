#!/bin/sh


#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#


set -e

DOMAIN="sig-spire.algol60.net"

echo "Running SPIRE server with domain $DOMAIN ..."

/opt/spire/bin/spire-server run -config /run/spire/config/server.conf 1>>/tmp/1.log 2>&1 &
PID=$!

echo "Server started as process $PID"

echo "Debugging ls /run/spire/sockets ..."
ls /run/spire/sockets || echo "failed"

echo "wtf - nothing"
echo "whoami?"

whoami

echo "Creating registration entry for spire/spire-agent..."

/opt/spire/bin/spire-server entry create \
    -node  \
    -spiffeID spiffe://$DOMAIN/ns/spire/sa/spire-agent \
    -selector k8s_sat:cluster:demo-cluster \
    -selector k8s_sat:agent_ns:spire \
    -selector k8s_sat:agent_sa:spire-agent -socketPath /run/spire/sockets/api.sock || echo "failed"

echo "Creating registration entry for tekton-chains/tekton-chains-controller..."


# Chains needs to be able to request an SVID
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://$DOMAIN/ns/tekton-chains/sa/tekton-chains-controller \
    -parentID spiffe://$DOMAIN/ns/spire/sa/spire-agent \
    -socketPath /run/spire/sockets/api.sock  \
    -selector k8s:ns:tekton-chains \
    -selector k8s:sa:tekton-chains-controller || echo "failed"

wait $PID

echo "Server stopped, exiting with failure"
exit 1
