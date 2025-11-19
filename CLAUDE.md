# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains Kuadrant QE Tekton-based CI/CD pipelines for automated testing and deployment. The pipelines run tests from the [Kuadrant testsuite](https://github.com/Kuadrant/testsuite), deploy Kuadrant components via [Helm](https://github.com/Kuadrant/helm-charts-olm), and provision OpenShift clusters for testing environments.

## Architecture

### Pipeline Organization

Pipelines are grouped by purpose in the `pipelines/` directory:

- **`pipelines/test/`** - Pipelines executing testsuite tests
  - `testsuite/` - Basic test execution pipeline with a single make target
  - `nightly/` - Comprehensive nightly testing (runs kuadrant, authorino-standalone, multicluster, dnstls-gcp, dnstls-azure, and disruptive tests)
  - `aro/`, `osd/`, `osd-upgrade/` - Cloud-specific test pipelines
  - `release/` - Release candidate validation pipeline

- **`pipelines/deploy/`** - Kuadrant deployment pipelines
  - `kuadrant-testsuite/` - Deploy Kuadrant via Helm for testing
  - `kuadrant-nightly-update/` - Nightly update pipeline

- **`pipelines/infra/`** - Cluster provisioning/deletion pipelines
  - `delete-aro/`, `delete-osd/`, `delete-rosa/` - Cleanup pipelines for different cluster types

- **`pipelines/misc/`** - Other pipelines
  - `dast/` - rapiDAST security scanning pipeline

### Task Organization

Reusable Tekton tasks in the `tasks/` directory:

- **`tasks/test/`** - Test execution tasks
  - `run-tests.yaml` - Core task that runs testsuite with configurable make targets
  - `upload-results.yaml` - Uploads test results to ReportPortal

- **`tasks/deploy/`** - Deployment tasks
  - `helm-deploy.yaml` - Deploy Kuadrant operators and instances via Helm (includes full cleanup/install cycle)
  - `check-image-existence.yaml` - Validate container images exist
  - `nightly-image-date.yaml` - Get nightly image timestamps

- **`tasks/infra/`** - Infrastructure management tasks
  - `provision-*.yaml` - Cluster provisioning for ARO, OSD (AWS/GCP), ROSA
  - `delete-*.yaml` - Cluster deletion tasks
  - `get-osd-credentials.yaml` - Extract cluster credentials
  - `operator-pod-restart.yaml` - Restart operator pods
  - `do-custom-updates.yaml` - Apply custom cluster updates

- **`tasks/login/`** - Authentication tasks
  - `kubectl-login.yaml` - Login to clusters and store kubeconfig in workspace

- **`tasks/misc/`** - Miscellaneous tasks
  - `clone-rapidast-repo.yaml`, `rapidast-scan.yaml`, `rapidast-cleanup.yaml` - rapiDAST DAST scanning
  - `compose-config-file.yaml` - Generate configuration files
  - `wait-for-job-to-complete.yaml` - Job monitoring

### Key Architecture Patterns

1. **Shared Workspace Pattern**: Pipelines use a shared workspace PVC to pass data between tasks (kubeconfigs, test results, etc.)

2. **Multi-cluster Testing**: The nightly pipeline logs into two clusters and passes kubeconfig paths between tasks for multi-cluster and standalone Authorino testing

3. **Helm-based Deployment**: Uses the official Kuadrant Helm charts from https://kuadrant.io/helm-charts-olm with a two-phase approach:
   - Install operators first (`tools-operators`, `kuadrant-operators`)
   - Then install instances (`tools-instances`, `kuadrant-instances`)

4. **Report Portal Integration**: All test results are uploaded to ReportPortal with launch metadata (name, description, OCP version)

5. **Make Target Execution**: Tests are executed via make targets from the testsuite repository:
   - `kuadrant` - Service Protection tests (AuthPolicy, RateLimitPolicy)
   - `authorino-standalone` - Standalone Authorino tests
   - `multicluster` - Multi-cluster tests
   - `dnstls` - DNSPolicy and TLSPolicy tests
   - `disruptive` - Disruptive tests

6. **Kustomize-based Pipeline Deployment**: Every pipeline has a `kustomization.yaml` file in its directory that applies the pipeline and all tasks it uses. This pattern enables task reuse across different pipelines and allows pipelines to be deployed with a single command: `oc apply -k pipelines/<type>/<pipeline>/`

## Common Commands

### Deploy a Pipeline

Deploy pipelines using kustomize:

```bash
# Deploy the basic testsuite pipeline
kubectl apply -k pipelines/test/testsuite/

# Deploy Kuadrant deployment pipeline
kubectl apply -k pipelines/deploy/kuadrant-testsuite/

# Deploy nightly test pipeline
kubectl apply -k pipelines/test/nightly/
```

### Execute Pipelines

Three methods to execute pipelines:

1. **OpenShift Web Console**: Navigate to Pipelines → Select pipeline → Start → Fill parameters

2. **tkn CLI**:
```bash
tkn pipeline start test-testsuite \
  --param kube-api="https://api.cluster.example.com:6443" \
  --param make-target="kuadrant" \
  --workspace name=shared-workspace,volumeClaimTemplateFile=pvc.yaml
```

3. **Direct PipelineRun creation**:
```bash
kubectl apply -f my-pipeline-run.yaml
```

## Required Secrets and ConfigMaps

Before running pipelines, you need to create the required OpenShift resources (secrets and ConfigMaps) in the pipeline namespace. The specific resources required for each pipeline type are documented in the project's README.md file.

## Pipeline Image

The CI automatically builds and pushes the `quay.io/kuadrant/testsuite-pipelines-tools` image containing tools used in the pipeline tasks:
- kubectl, helm, ocm, rosa, opm, aws CLI, azure CLI
- Python 3.11 with osia package
- buildah, jq, git, tar, findutils

Manual builds should only be performed in emergencies. See README.md for manual build instructions.

## Pipeline Parameters Reference

### Common Test Pipeline Parameters

- `testsuite-image` - Testsuite container image (default: `quay.io/kuadrant/testsuite:unstable`)
- `kube-api` - Kubernetes API URL (required)
- `cluster-credentials` - Secret name with cluster credentials (default: `openshift-pipelines-credentials`)
- `project` - OpenShift project/namespace for tests (default: `kuadrant`)
- `make-target` - Makefile target to execute (e.g., `kuadrant`, `authorino-standalone`, `multicluster`, `dnstls`, `disruptive`)
- `pytest-flags` - Additional pytest flags (e.g., `-k test_name` for specific tests)
- `settings-cm` - ConfigMap with testsuite settings (default: `pipeline-settings`)
- `additional-env` - Space-separated environment variables (e.g., `KUADRANT_CONTROL_PLANE__provider_secret=gcp-credentials`)
- `launch-name` - ReportPortal launch name prefix (default: `pipeline`, use `kuadrant-v1.2.0` for releases)
- `launch-description` - Optional ReportPortal launch description
- `rp-project` - ReportPortal project name (default: `testsuite`, use `nightly-testsuite` for nightlies, `releases` for release candidates)
- `upload-results` - Upload to ReportPortal (default: `true`)

### Common Deploy Pipeline Parameters

- `index-image` - Kuadrant operator catalog image (e.g., `quay.io/kuadrant/kuadrant-operator-catalog:v1.3.1`)
- `channel` - Operator channel (`preview` for nightlies, `stable` for releases)
- `operator-name` - Operator name (`kuadrant-operator` or `rhcl-operator`)
- `istio-provider` - Istio provider (`ossm3` recommended, `ocp` for OCP 4.19+ Gateway API-managed Istio)
- `gateway-crd` - GatewayAPI CRD version (e.g., `v1.2.1`, `v1.3.0`, `v1.4.0`, empty for OCP 4.19+)
- `additional-helm-flags` - Extra helm flags for operators/instances (e.g., `--set=kuadrant.installPlanApproval=Manual`)
- `additional-helm-tools-flags` - Extra helm flags for tools (e.g., `--set=tools.keycloak.keycloakProvider=deployment`)

## Development Workflow

When modifying pipelines or tasks:

1. **Test changes locally**: Use `tkn` to start a PipelineRun with your modified resources
2. **Update kustomization.yaml**: Ensure new tasks are referenced in the appropriate `kustomization.yaml`
3. **Redeploy**: `kubectl apply -k pipelines/<type>/<pipeline>/` to apply changes
4. **Validate**: Check PipelineRun logs via OpenShift Console or `tkn pr logs <name> -f`
5. **Commit**: Pipeline image CI will rebuild automatically on merge

## Important Notes

- The nightly pipeline runs tests sequentially across multiple make targets and clusters
- The `helm-deploy` task performs a full cleanup (uninstall) before installing to ensure clean state
- Multi-cluster tests require two cluster logins (primary and secondary) with kubeconfigs stored in the shared workspace
- Test results are always saved to the shared workspace volume on the cluster, even if upload to ReportPortal is disabled
- For release testing, use launch names like `kuadrant-v1.2.0` and the `releases` ReportPortal project
- The testsuite image is maintained in a separate repository and consumed here
- QE secrets and some additional configurations are set from the private overlay of this repository, not included in the public repo
