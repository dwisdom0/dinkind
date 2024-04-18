# Quickstart

Install
[Docker](https://docs.docker.com/get-docker/),
[kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation),
[kubectl](https://kubernetes.io/docs/tasks/tools/),
[Helm](https://helm.sh/docs/intro/install/),
and (optionally) [k9s](https://k9scli.io/topics/install/).

You probably have most of these already if you're interacting with a Kubernetes cluster.

```shell
./run_everything.sh
```

Open `localhost:8080` in a browser to see the Dagster UI.


If you want to look at the deployment a bit, tell `kubectl` to use the kubeconfig that `kind` generated.
```
export KUBECONFIG='./.kube/config'
```

Then you can use `kubectl` or `k9s` to look into things.
It should default to the `dinkind` namespace, so you'll only see the `dinkind` stuff.
```shell
kubectl get pods
NAME                                                        READY   STATUS      RESTARTS   AGE
dagster-run-714f2785-147f-4b94-8410-7cb1cbe3cbe0-cx922      0/1     Completed   0          47m
dinkind-dagster-daemon-895948f9f-mbvkk                      1/1     Running     0          49m
dinkind-dagster-user-deployments-dinkind-7487fd4cf6-qtv97   1/1     Running     0          49m
dinkind-dagster-webserver-79958b9748-8qcln                  1/1     Running     0          49m
dinkind-postgresql-0                                        1/1     Running     0          49m
```

# Quickend
```shell
./teardown_everything.sh
```
This cleanup script deletes everything with impunity.
Just as a heads up, part of this script kills all `kubectl` processes.



# What does this even do?

* Spin up a `kind` cluster
* Spin up a local Docker image registry
* Build a custom Dagster Code Location (i.e., your ETL pipelines) and put it in the local Docker registry
* Deploy Dagster in the `kind` cluster using Helm, pulling the Code Location from the local Docker regsitry

After all that, you can run ETL pipelines from Dagster in a local Kubernetes cluster.

# Why? Doesn't Dagster run locally out of the box?
Yes, Dagster can run ETL pipelines locally.
But production pipelines often run in Kuberentes.

This script is mainly for debugging the Kuberentes side of things.

For example, say job pods are sticking around for too long after they complete—you'd like to delete them after just a few seconds.
To do that, you have to set `ttlSecondsAfterFinished` somewhere deep in the `values.yaml`.
With this script, you can experiment and debug locally until you've figured out how exactly to make that change work.
You don't have to deploy a speculative change to your dev cluster, wait for the error message there, debug, and redeploy all day.


# Performance

On my machine, Docker Desktop says this whole setup uses 1.6 GB of memory and about a third of a CPU while I'm randomly clicking around in the Dagster UI.
The image for `kind` and the Code Location image are both about 1 GB each.
The image for the local Docker regsitry is only 25 MB.

I think that's pretty decent for a Kubernetes cluster plus a web app.

Plus it's hilarious.
