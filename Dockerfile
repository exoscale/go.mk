ARG EXOSCALE_DOCKER_REGISTRY=registry.internal.exoscale.ch

FROM ${EXOSCALE_DOCKER_REGISTRY}/exoscale/ubuntu:jammy

RUN set -xe \
    && apt-get update -q \
    && apt-get install -y -q build-essential git rsync golang \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY /release.mk /
RUN GO=go make --makefile=/release.mk install-goreleaser \
    && rm -rf /root/go/pkg
ENV PATH /root/go/bin:$PATH


COPY release-in-docker.sh /

CMD ["/release-in-docker.sh"]
