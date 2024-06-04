testsuite-pipelines
===
This repository contains Kuadrant testsuite pipeline objects

Deployment
---
* Install the `openshift-pipelines` Openshift operator on the cluster
* Apply all pipelines and their resources `oc apply -k src/ -n ${PIPELINE_NAMESPACE}`

Secrets
---
Prior to the running of the pipeline, the following resources must be created in the pipeline namespace:
- Opaque Secret named `openshift-pipelines-credentials` containing `KUBE_PASSWORD` and `KUBE_USER` keys 
with the credentials to access the testing cluster. E.g.
```shell
kubectl create secret generic openshift-pipelines-credentials --from-literal=KUBE_USER="admin" --from-literal=KUBE_PASSWORD="admin" -n ${PIPELINE_NAMESPACE}
```
- Opaque Secret named `rp-credentials` containing `RP_URL` key with the URL of the ReportPortal instance 
and `RP_TOKEN` key with the ReportPortal user access token. E.g.
```shell
kubectl create secret generic rp-credentials --from-literal=RP_URL="https://reportportal-kuadrant-qe.example.io" --from-literal=RP_TOKEN="api-token" -n ${PIPELINE_NAMESPACE}
```
- ConfigMap named `rp-ca-bundle` containing the certificates trusted by the ReportPortal instance under the `tls-ca-bundle.pem` key. E.g.
```shell
kubectl create cm rp-ca-bundle --from-file=tls-ca-bundle.pem=./tls-ca-bundle.pem -n ${PIPELINE_NAMESPACE}
```
- ConfigMap with testsuite settings under the `settings.local.yaml` key which is later can be used as a parameter for the pipeline run. E.g.
```shell
kubectl create cm pipeline-settings-default --from-file=settings.local.yaml=./settings.yaml -n ${PIPELINE_NAMESPACE}
```

Pipeline execution
---
1. Through the OpenShift Web Console
    - Navigate to the `Pipelines` section in the OpenShift Web Console
    - Click on the `Pipeline` object to be executed
    - Click on the `Start` button
    - Fill in the required parameters
    - Click on the `Start` button
2. Apply the `PipelineRun` resource directly
    - Create the new `PipelineRun` resource directly in the namespace with pipeline
    - `PipelineRun` resource should contain all required parameters
3. Using the `tkn` CLI
    - Install the `tkn` CLI tool
    - Execute the `tkn pipeline start` command with the required parameters

Trigger nightly pipeline manually
---
```shell
# kuadrant
kubectl create job --from=cronjob/trigger-nightly-kuadrant trigger-nightly-kuadrant-$(date +%d.%m)-$(whoami)-manual -n ${PIPELINE_NAMESPACE}
# authorino-standalone
kubectl create job --from=cronjob/trigger-nightly-authorino-standalone trigger-nightly-authorino-standalone-$(date +%d.%m)-$(whoami)-manual -n ${PIPELINE_NAMESPACE}
```
