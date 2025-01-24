FROM registry.redhat.io/ubi8/ubi-minimal:latest

RUN curl -Lso ocm https://github.com/openshift-online/ocm-cli/releases/download/v1.0.3/ocm-linux-amd64 && chmod +x ocm && mv ocm /usr/local/bin && microdnf install jq
