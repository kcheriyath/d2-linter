FROM debian:bookworm-slim

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

# Download d2, verify checksum, extract binary, then clean up curl
RUN D2_TAR="d2-v${D2_VERSION}-linux-amd64.tar.gz" \
    && curl -fsSL "https://github.com/terrastruct/d2/releases/download/v${D2_VERSION}/${D2_TAR}" \
         -o /tmp/d2.tar.gz \
    && echo "eb172adf59f38d1e5a70ab177591356754ffaf9bebb84e0ca8b767dfb421dad7  /tmp/d2.tar.gz" | sha256sum -c \
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
