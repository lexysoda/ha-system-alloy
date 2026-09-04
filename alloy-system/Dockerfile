ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    bash \
    jq \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG BUILD_ARCH
ARG ALLOY_VERSION=1.13.1

RUN set -eux; \
    case "${BUILD_ARCH}" in \
        amd64)   ARCH="linux-amd64" ;; \
        aarch64) ARCH="linux-arm64" ;; \
        *) echo "Unsupported arch: ${BUILD_ARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/grafana/alloy/releases/download/v${ALLOY_VERSION}/alloy-${ARCH}.zip" -o /tmp/alloy.zip; \
    unzip /tmp/alloy.zip -d /tmp/alloy-extract; \
    mv /tmp/alloy-extract/alloy-${ARCH} /usr/bin/alloy; \
    chmod +x /usr/bin/alloy; \
    rm -rf /tmp/alloy.zip /tmp/alloy-extract

COPY rootfs /
