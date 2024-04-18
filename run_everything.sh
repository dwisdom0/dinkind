#! /bin/sh
set -euxo pipefail

# start kind (k8s in docker)
export KUBECONFIG='./.kube/config'
# have to use a custom config to use a local Docker registry
# https://kind.sigs.k8s.io/docs/user/local-registry/
kind create cluster \
  --name kind \
  --wait 2m \
  --config=kind_config.yaml

# create a namespace and make that the default place we're working
# by editing kind's context (kind-kind)
kubectl create namespace dinkind
kubectl config set-context kind-kind --namespace dinkind
kubectl get namespaces

# Start a local Docker registry
# so we can push our image there once we build it
# https://www.docker.com/blog/how-to-use-your-own-registry-2/
#
# turns out it's more complicated than this
# since we have to forward "localhost:5000" to the host
# instead of using K8s internal localhost
# https://kind.sigs.k8s.io/docs/user/local-registry/
# https://iximiuz.com/en/posts/kubernetes-kind-load-docker-image/

reg_name='dinkind-registry'
reg_port=5001
reg_addr="127.0.0.1:$reg_port"

# get a local regsitry running
# this will fail if there's already one running
# the kind doc version checks for that
# but I'm just doing this
# run the teardown script before running this script
docker run \
  -d \
  -p "$reg_addr:5000" \
  --restart unless-stopped \
  --network bridge \
  --name $reg_name \
  registry:2.8

# add the local registry to each node
# I think we should only have one node but I'm copy/pasting this from
# the example in kind's docs
# some more info about what this is supposed to look like
# https://github.com/containerd/containerd/blob/release/1.5/docs/hosts.md#cri
#
# I ended up changing their thing a tiny bit to match this
# https://stackoverflow.com/a/67310470
# Their way wasn't working, but it worked once I put the hosts.toml at
# /etc/containerd/certs.d/dinkind-registry:5000
# instead of
# /etc/containerd/certs.d/localhost:5001
# so maybe their docs are just wrong or something?
# Or maybe they're trying to do something fancier that I don't understand
# and don't need
REGISTRY_DIR="/etc/containerd/certs.d/$reg_name:5000"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://$reg_name:5000"]
EOF
done

# connect the registry to the cluster's network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# the example just says "document the registry"
# I didn't read their github link so I don't really know what this does
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF


# Build our Code Location and put it in the local registry
image_version='0.0.1'
docker build . -t $reg_addr/dinkind_code_location:$image_version
docker push $reg_addr/dinkind_code_location:$image_version


# Use Helm to install Dagster,
# pulling our Code Location image from our local registry
# inside values.local.yaml
helm repo add dagster https://dagster-io.github.io/helm
helm repo update
helm upgrade \
  --install dinkind dagster/dagster \
  -f values.local.yaml \
  --atomic


# set up the port forward into the Dagster GUI silently in the background
export DAGSTER_WEBSERVER_POD_NAME=$(kubectl get pods -l "app.kubernetes.io/name=dagster,app.kubernetes.io/instance=dinkind,component=dagster-webserver" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $DAGSTER_WEBSERVER_POD_NAME 8080:80 > /dev/null 2>&1 &
echo ""
echo "Ignore the above message. The port forward is already active."
echo "Visit http://127.0.0.1:8080 to open the Dagster UI"
echo ""
