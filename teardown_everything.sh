#! /bin/sh
set -euxo pipefail

# turn off the port forward
pkill kubectl
echo "Killed all kubectl processes"

# destroy the local registry
docker stop dinkind-registry
docker rm dinkind-registry
echo "Destroyed the local Docker image registry"

# remove the Code Location image
docker image rm 127.0.0.1:5001/dinkind_code_location:0.0.1
echo "Deleted the custom Dagster Code Location image"

# destroy everything
# also wipes the kubeconfig
kind delete cluster --name kind
echo "Destroyed the local kind cluster"
