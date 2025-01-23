# Containerfile/Dockerfile
ARG UBUNTU_VERSION=20.04

FROM docker.io/library/ubuntu:${UBUNTU_VERSION} as build

RUN apt update && apt upgrade -y

WORKDIR /opt

ENTRYPOINT ["/bin/bash"]
CMD ["-i", "--login"]
