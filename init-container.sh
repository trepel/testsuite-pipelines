#!/bin/bash
set -o pipefail

case "${TARGETPLATFORM}" in
    "linux/amd64") ARCH=amd64 && ROSA_ARCH=x86_64 && AWS_ARCH=x86_64 ;;
    "linux/arm64") ARCH=arm64 && ROSA_ARCH=arm64 && AWS_ARCH=aarch64 ;;
    *) exit 1 ;;
esac

microdnf -y install jq tar git buildah findutils unzip

curl -LSs -o /usr/local/bin/ocm "https://github.com/openshift-online/ocm-cli/releases/download/$(curl -Lfs https://api.github.com/repos/openshift-online/ocm-cli/releases/latest \
    | jq -r .tag_name)/ocm-linux-${ARCH}" \
    && chmod 0755 /usr/local/bin/ocm
curl -Lfs "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash  # installs to /usr/local/bin/helm

curl -LSs -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -Lfs https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
    && chmod 0755 /usr/local/bin/kubectl

curl -Lfs "https://github.com/openshift/rosa/releases/download/$(curl -Lfs https://api.github.com/repos/openshift/rosa/releases/latest \
    | jq -r .tag_name)/rosa_Linux_${ROSA_ARCH}.tar.gz" | \
    tar -xz -f - -C /usr/local/bin 'rosa' \
    && chmod 0755 /usr/local/bin/rosa

curl -LSs -o /usr/local/bin/opm "https://github.com/operator-framework/operator-registry/releases/download/$(curl -Lfs https://api.github.com/repos/operator-framework/operator-registry/releases/latest \
    | jq -r .tag_name)/linux-${ARCH}-opm" \
    && chmod 0755 /usr/local/bin/opm

curl -LSs -o awscli.zip "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
    && unzip awscli.zip \
    && ./aws/install -i /usr/local/aws -b /usr/local/bin \
    && rm -rf ./aws ./awscli.zip

rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && rpm -Uvh https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm \
    && microdnf -y install azure-cli
