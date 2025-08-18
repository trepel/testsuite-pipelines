FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
ARG TARGETPLATFORM
COPY init-container.sh .
RUN /bin/bash init-container.sh
CMD ["/bin/bash"]
