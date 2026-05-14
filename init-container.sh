#!/bin/bash
set -euo pipefail

case "${TARGETPLATFORM}" in
    "linux/amd64") ARCH=amd64 && ROSA_ARCH=x86_64 && AWS_ARCH=x86_64 && NODE_ARCH=x64 ;;
    "linux/arm64") ARCH=arm64 && ROSA_ARCH=arm64 && AWS_ARCH=aarch64 && NODE_ARCH=arm64 ;;
    *) exit 1 ;;
esac

microdnf -y install jq tar xz git buildah findutils unzip python3.11 python3.11-pip make gettext

curl -LSs -o /usr/local/bin/ocm "https://github.com/openshift-online/ocm-cli/releases/download/$(curl -Lfs https://api.github.com/repos/openshift-online/ocm-cli/releases/latest \
    | jq -r .tag_name)/ocm-linux-${ARCH}" \
    && chmod 0755 /usr/local/bin/ocm
curl -Lfs "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash  # installs to /usr/local/bin/helm

curl -LSs -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -Lfs https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
    && chmod 0755 /usr/local/bin/kubectl

curl -Lfs "https://mirror.openshift.com/pub/openshift-v4/${AWS_ARCH}/clients/ocp/stable/openshift-client-linux-${ARCH}-rhel9.tar.gz" | \
    tar -xz -f - -C /usr/local/bin 'oc' \
    && chmod 0755 /usr/local/bin/oc

curl -Lfs "https://github.com/openshift/rosa/releases/download/$(curl -Lfs https://api.github.com/repos/openshift/rosa/releases/latest \
    | jq -r .tag_name)/rosa_Linux_${ROSA_ARCH}.tar.gz" | \
    tar -xz -f - -C /usr/local/bin 'rosa' \
    && chmod 0755 /usr/local/bin/rosa

curl -LSs -o /usr/local/bin/opm "https://github.com/operator-framework/operator-registry/releases/download/$(curl -Lfs https://api.github.com/repos/operator-framework/operator-registry/releases/latest \
    | jq -r .tag_name)/linux-${ARCH}-opm" \
    && chmod 0755 /usr/local/bin/opm

curl -LSs -o /usr/local/bin/cli53 "https://github.com/barnybug/cli53/releases/download/$(curl -Lfs https://api.github.com/repos/barnybug/cli53/releases/latest \
    | jq -r .tag_name)/cli53-linux-${ARCH}" \
    && chmod 0755 /usr/local/bin/cli53

NODE_VERSION=$(curl -Lfs https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version') \
    && curl -Lfs "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" | \
    tar -xJ -f - --strip-components=1 -C /usr/local

curl -LSs -o awscli.zip "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
    && unzip awscli.zip \
    && ./aws/install -i /usr/local/aws -b /usr/local/bin \
    && rm -rf ./aws ./awscli.zip

rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && rpm -Uvh https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm \
    && microdnf -y install azure-cli

python3.11 -m pip install --no-cache-dir osia
