ARG DOCKER_IMAGE_REGISTRY=docker.io
FROM ${DOCKER_IMAGE_REGISTRY}/library/alpine:3.23

ARG APK_MIRROR_URL=https://linux-mirror.liara.ir/repository/alpine
ARG RC_VERSION=v0.1.30

RUN echo "${APK_MIRROR_URL}/v3.23/main" > /etc/apk/repositories && \
    echo "${APK_MIRROR_URL}/v3.23/community" >> /etc/apk/repositories

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    openssl \
    gnupg \
    postgresql17-client

WORKDIR /tmp

RUN curl -fLO \
    "https://github.com/rustfs/cli/releases/download/${RC_VERSION}/rustfs-cli-linux-amd64-${RC_VERSION}.tar.gz" \
    -o /tmp/rustfs-cli-linux-amd64-${RC_VERSION}.tar.gz && \
    tar -xzf rustfs-cli-linux-amd64-${RC_VERSION}.tar.gz && \
    install -m 0755 rc /usr/local/bin/rc && \
    rm -rf /tmp/*

WORKDIR /app

COPY entrypoint.sh .
# RUN chmod +x entrypoint.sh

# ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/entrypoint.sh", "backup"]