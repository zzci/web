FROM alpine:3.24

ARG SWS_VERSION=2.43.0
ARG TARGETARCH

RUN apk add --no-cache ca-certificates tzdata && \
    SWS_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    wget -qO- "https://github.com/static-web-server/static-web-server/releases/download/v${SWS_VERSION}/static-web-server-v${SWS_VERSION}-${SWS_ARCH}-unknown-linux-musl.tar.gz" \
    | tar -xzf - -C /usr/local/bin --strip-components=1 \
      "static-web-server-v${SWS_VERSION}-${SWS_ARCH}-unknown-linux-musl/static-web-server" && \
    chmod +x /usr/local/bin/static-web-server && \
    rm -rf /tmp/*

RUN mkdir -p /web

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /web

ENV SERVER_PORT=80 \
    SERVER_ROOT=/web \
    SERVER_LOG_LEVEL=warn

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
