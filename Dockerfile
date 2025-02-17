FROM quay.io/app-sre/ubi9-ubi-minimal:latest

RUN microdnf -y install jq tar git

RUN curl -LSs -o /usr/local/bin/ocm "https://github.com/openshift-online/ocm-cli/releases/download/$(curl -Lfs https://api.github.com/repos/openshift-online/ocm-cli/releases/latest \
    | jq -r .tag_name)/ocm-linux-amd64" \
    && chmod 0755 /usr/local/bin/ocm
RUN curl -Lfs "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash  # installs to /usr/local/bin/helm
RUN curl -LSs -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -Lfs https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod 0755 /usr/local/bin/kubectl
RUN curl -Lfs "https://github.com/openshift/rosa/releases/download/$(curl -Lfs https://api.github.com/repos/openshift/rosa/releases/latest \
    | jq -r .tag_name)/rosa_Linux_x86_64.tar.gz" | \
    tar -xz -f - -C /usr/local/bin 'rosa' \
    && chmod 0755 /usr/local/bin/rosa

CMD ["/bin/bash"]
