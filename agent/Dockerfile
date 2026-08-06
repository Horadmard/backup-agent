ARG DOCKER_IMAGE_REGISTRY=docker.io
FROM ${DOCKER_IMAGE_REGISTRY}/library/alpine:3.23

ARG APK_MIRROR_URL=https://dl-cdn.alpinelinux.org/alpine
ARG RC_VERSION=0.1.30

RUN echo "${APK_MIRROR_URL}/v3.23/main" > /etc/apk/repositories && \
    echo "${APK_MIRROR_URL}/v3.23/community" >> /etc/apk/repositories

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    unzip \
    openssl \
    gnupg \
    postgresql17-client

RUN curl -L \
    "https://github.com/rustfs/cli/releases/download/v${RC_VERSION}/rc-linux-amd64-musl.zip" \
    -o /tmp/rc.zip && \
    unzip /tmp/rc.zip -d /tmp && \
    install -m 755 /tmp/rc /usr/local/bin/rc && \
    rm -rf /tmp/*

WORKDIR /app

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]