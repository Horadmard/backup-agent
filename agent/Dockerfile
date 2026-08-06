ARG DOCKER_IMAGE_REGISTRY=docker.io
FROM ${DOCKER_IMAGE_REGISTRY}/library/alpine:3.23

ARG APK_MIRROR_URL=https://linux-mirror.liara.ir/repository/alpine
ARG RC_VERSION=0.1.30

RUN echo "${APK_MIRROR_URL}/v3.23/main" > /etc/apk/repositories && \
    echo "${APK_MIRROR_URL}/v3.23/community" >> /etc/apk/repositories

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    openssl \
    gnupg \
    postgresql17-client

WORKDIR /tmp

RUN curl -fLO \
    "https://github.com/rustfs/cli/releases/download/v0.1.30/rustfs-cli-linux-amd64-v0.1.30.tar.gz" \
    -o /tmp/rustfs-cli-linux-amd64-v0.1.30.tar.gz && \
    tar -xzf rustfs-cli-linux-amd64-v0.1.30.tar.gz && \
    install -m 0755 rc /usr/local/bin/rc && \
    rm -rf /tmp/*

WORKDIR /app

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

CMD ["/app/entrypoint.sh"]