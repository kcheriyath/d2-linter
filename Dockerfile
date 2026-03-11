FROM debian:12.5-slim

ARG D2_VERSION=0.7.1

LABEL version="0.1.0"
LABEL repository="https://github.com/kcheriyath/d2-linter"
LABEL homepage="https://github.com/kcheriyath/d2-linter"
LABEL maintainer="K Cheriyath <kcher-developer@outlook.com>"

# Install only what is needed to download d2, then remove it
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# SHA-256 checksums for d2 v0.7.1 (from GitHub release asset digests)
ARG D2_SHA256_AMD64=eb172adf59f38d1e5a70ab177591356754ffaf9bebb84e0ca8b767dfb421dad7
ARG D2_SHA256_ARM64=ce3a0b985a8f91335a826c254b3a88736fd81afcdd08b58f6c749d2add6864b0

# Download d2, verify checksum, extract binary, then clean up curl
RUN set -e \
    && arch="$(uname -m)" \
    && case "$arch" in \
         x86_64) d2_arch="amd64"; d2_sha256="${D2_SHA256_AMD64}" ;; \
         aarch64|arm64) d2_arch="arm64"; d2_sha256="${D2_SHA256_ARM64}" ;; \
         *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
       esac \
    && D2_TAR="d2-v${D2_VERSION}-linux-${d2_arch}.tar.gz" \
    && curl -fsSL "https://github.com/terrastruct/d2/releases/download/v${D2_VERSION}/${D2_TAR}" \
         -o /tmp/d2.tar.gz \
    && echo "${d2_sha256}  /tmp/d2.tar.gz" | sha256sum -c - \
    && tar xz -C /tmp -f /tmp/d2.tar.gz \
    && find /tmp -path "*/bin/d2" -type f -exec install -m 0755 {} /usr/local/bin/d2 \; \
    && rm -rf /tmp/d2.tar.gz /tmp/d2-* \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run the linter
RUN useradd --system --no-create-home --shell /usr/sbin/nologin linter

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER linter

ENTRYPOINT ["/entrypoint.sh"]
