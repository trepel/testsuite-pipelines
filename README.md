testsuite-pipelines
===
This repository contains Kuadrant testsuite pipeline objects

Deployment
---
1. Install the `openshift-pipelines` Openshift operator on the cluster
2. Deploy pipeline by running `kubectl apply -k pipelines/<pipeline-dir>/<pipeline>/` on the desired pipeline directory. Pipelines are grouped by their purpose:
   - `pipelines/test/` - pipelines that execute testsuite tests
   - `pipelines/deploy/` - pipelines that deploy Kuadrant on clusters
   - `pipelines/infra/` - pipelines for provisioning and managing kubernetes clusters
   - `pipelines/misc/` - other pipelines, e.g. for rapiDAST security scans

Required secrets and configmaps
---
Prior to the running of the pipeline, the following resources must be created in the pipeline namespace:

#### Resources required to run test/ pipelines
- Opaque Secret (pipelines expect `openshift-pipelines-credentials` name by default but custom name can be specified via `cluster-credentials` input parameter) containing `KUBE_PASSWORD` and `KUBE_USER` keys 
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
- ConfigMap with testsuite settings under the `settings.local.yaml` key. Just copy the default testsuite settings if you don't need anything else. E.g.
```shell
kubectl create cm pipeline-settings --from-file=settings.local.yaml=./settings.local.yaml -n ${PIPELINE_NAMESPACE}
```

- Opaque Secret named additional-auth-entries containing "auth" sections that will be added to global pull secret. Useful if consuming images from private registries.
```shell
export ADDITIONAL_AUTH_ENTRIES='"desired.registry.io": {"auth": "base64-encoded-creds"}'
kubectl create secret generic additional-auth-entries --from-literal="additional-auth-entries=$ADDITIONAL_AUTH_ENTRIES" -n "${PIPELINE_NAMESPACE}"
```

#### Resources required to run deploy/ pipelines
- Opaque Secret named values-additional-manifests containing secrets for testsuite run. Example: https://github.com/azgabur/kuadrant-helm-install/blob/main/example-additionalManifests.yaml
```shell
kubectl create -n ${PIPELINE_NAMESPACE} secret generic values-additional-manifests --from-file=additionalManifests.yaml=${ADDITIONAL_MANIFESTS.yaml}
```

#### Resources required to run infra/ pipelines
- Opaque secret containing AWS credentials for `osdCcsAdmin` IAM user (pipelines provisioning clusters in AWS only). E.g.
```shell
kubectl create secret generic kua-aws-credentials --from-literal=AWS_ACCOUNT_ID="xxx" --from-literal=AWS_ACCESS_KEY_ID="xxx" --from-literal=AWS_SECRET_ACCESS_KEY="xxx" -n ${PIPELINE_NAMESPACE}
```

- Opaque secret containing HCC client credentials (pipelines provisioning clusters via HCC (OCM) only). E.g.
```shell
kubectl create secret generic kua-ocm-stage-client-credentials --from-literal=CLIENT_ID="xxx" --from-literal=CLIENT_SECRET="xxx" -n ${PIPELINE_NAMESPACE}
```

- Opaque secret containing GCP credentials for `osd-ccs-admin` IAM user (pipelines provisioning clusters in GCP only). E.g.
```shell
kubectl create secret generic kua-gcp-credentials --from-file=gcp-osd-ccs-admin-sa-security-key.json -n ${PIPELINE_NAMESPACE}
```

- Opaque secret containing ROSA credentials for an IAM user (pipelines provisioning ROSA cluster only). E.g.
```shell
kubectl create secret generic kua-rosa-credentials --from-literal=AWS_ACCOUNT_ID="xxx" --from-literal=AWS_ACCESS_KEY_ID="xxx" --from-literal=AWS_SECRET_ACCESS_KEY="xxx" -n ${PIPELINE_NAMESPACE}
```

- Opaque secret containing service principal credentials for Azure Portal (pipelines provisioning ARO cluster only). E.g.
```shell
kubectl create secret generic kua-azure-credentials --from-literal=APP_ID="xxx" --from-literal=PASSWORD="xxx" --from-literal=TENANT_ID="xxx" --from-literal=SUBSCRIPTION_ID="xxx" -n ${PIPELINE_NAMESPACE}
```

- Pull secret containing auth sections for brew and stage (optional) registries (pipelines provisioning ARO cluster only). E.g.
```shell
kubectl create secret generic aro-pull-secret --from-file=.dockerconfigjson=/path/to/your/auths.json  --type=kubernetes.io/dockerconfigjson -n ${PIPELINE_NAMESPACE}
```

#### Resources required for rapiDAST pipeline
- Opaque secret containing credentials for Google Cloud storage where rapiDAST scan results will be stored. E.g.
```shell
kubectl create secret generic rapidast-storage-access-key --from-file=rapidast-sa-rhcl_key.json=/local/path/to/your-service-account_key.json -n ${PIPELINE_NAMESPACE}
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

Useful commands
---
* Trigger nightly pipeline manually
```shell
kubectl create job --from=cronjob/trigger-nightly-testsuite-cron trigger-nightly-pipeline-$(date +%d.%m)-$(whoami)-manual -n ${PIPELINE_NAMESPACE}
```

* Set default dns configuration for Tekton pods
```shell
resolver1="1.2.3.4" # Change me
resolver2="2.3.4.5" # Change me
kubectl patch tektonconfig config --type merge -p "{\"spec\": {\"pipeline\": {\"default-pod-template\": \"dnsConfig:\n  nameservers:\n    - ${resolver1}\n    - ${resolver2}\ndnsPolicy: None\"}}}"
```

* Setup automatic cleanup of old PipelineRun's every week
```shell
kubectl patch tektonconfig config --type=merge -p '{"spec":{"pruner":{"disabled":false,"keep":null,"keep-since":10080,"resources":["pipelinerun"],"schedule":"0 0 * * 0"}}}'
```

Pipeline image
---
If `Dockerfile` or `init.container.sh` has been modified, use either `podman` or `docker` to rebuild it.

Set the TAG env variable to an increment of the last version in https://quay.io/repository/kuadrant/testsuite-pipelines-tools?tab=tags

Only members of [QE Team](https://quay.io/organization/kuadrant/teams/qe) and `kuadrant+qe` robot account are allowed to do the push.

### Podman
You might need to install QEMU User Static Emulation and enable Binary Format Support.
```shell
# Fedora example
sudo dnf install qemu-user-static
sudo systemctl start systemd-binfmt.service
```

It is also possible to use container:
```shell
podman run --rm --privileged mirror.gcr.io/multiarch/qemu-user-static --reset -p yes
```

To build multiarch (AMD64 and ARM64) image execute:
```shell
podman build --no-cache --platform linux/arm64 -t testsuite-pipelines-tools:latest-arm64 .
podman build --no-cache --platform linux/amd64 -t testsuite-pipelines-tools:latest-amd64 .
podman manifest rm testsuite-pipelines-tools:latest
podman manifest create testsuite-pipelines-tools:latest
podman manifest add testsuite-pipelines-tools:latest testsuite-pipelines-tools:latest-arm64
podman manifest add testsuite-pipelines-tools:latest testsuite-pipelines-tools:latest-amd64
podman manifest push testsuite-pipelines-tools:latest quay.io/kuadrant/testsuite-pipelines-tools:latest
export TAG=0.x;podman manifest push testsuite-pipelines-tools:latest quay.io/kuadrant/testsuite-pipelines-tools:$TAG
```

### Docker
Install [docker buildx](https://github.com/docker/buildx)
(note: also install QEMU packages), be sure you are logged in quay.io and run:

```shell
TAG=0.x docker buildx bake 
```
