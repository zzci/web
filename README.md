# zzci/web

A tiny, multi-arch Docker image for serving static websites, built on
[Static Web Server (SWS)](https://static-web-server.net/) and Alpine Linux.

- **Small** — Alpine plus a single static musl binary; a few MB total.
- **Fast** — SWS is an asynchronous web server written in Rust (Hyper / Tokio).
- **Multi-arch** — `linux/amd64` and `linux/arm64`.
- **Zero-config** — serves `/web` on port `80` out of the box.
- **Configurable** — environment variables, CLI flags, or a TOML config file.

## Image

| | |
|---|---|
| Registry | Docker Hub — [`zzci/web`](https://hub.docker.com/r/zzci/web) |
| Tags | `latest`, `YYYYMMDD` (build date), and version tags on releases |
| Base | `alpine:3.24` |
| Server | Static Web Server `v2.43.0` |
| Document root | `/web` |
| Exposed port | `80` |

## Quick start

Serve a local folder (read-only mount) on <http://localhost:8080>:

```bash
docker run --rm -p 8080:80 -v "$PWD:/web:ro" zzci/web
```

Bake your site into an image:

```dockerfile
FROM zzci/web
COPY ./dist /web
```

```bash
docker build -t my-site .
docker run --rm -p 8080:80 my-site
```

## Configuration

**Environment variables are the recommended way to configure the server** — they
cover almost every option and fit container/orchestrator workflows cleanly. Two
extra mechanisms exist for the remaining cases, in increasing order of precedence:

1. **Environment variables** — prefixed `SERVER_*` (use these by default).
2. **CLI flags** — anything after the image name is passed straight to SWS.
3. **TOML config file** — only needed for advanced routing (custom headers,
   redirects, rewrites, virtual hosts); takes precedence over the two above.

### Environment variables

Every SWS flag has a `SERVER_*` counterpart. The image presets the four below;
all other variables fall back to the SWS defaults. Full list:
<https://static-web-server.net/configuration/environment-variables/>.

| Variable | Image default | Description |
|---|---|---|
| `SERVER_HOST` | `::` | Bind address (`::` accepts both IPv4 and IPv6) |
| `SERVER_PORT` | `80` | Listening port |
| `SERVER_ROOT` | `/web` | Directory served |
| `SERVER_LOG_LEVEL` | `warn` | `error` / `warn` / `info` / `debug` / `trace` |
| `SERVER_CONFIG_FILE` | — | Path to a TOML config file (see below) |
| `SERVER_COMPRESSION` | `true` | Gzip / Brotli / Zstd / Deflate, negotiated per request |
| `SERVER_COMPRESSION_STATIC` | `false` | Serve pre-compressed `*.gz` / `*.br` / `*.zst` siblings |
| `SERVER_CACHE_CONTROL_HEADERS` | `true` | Sensible `Cache-Control` headers per file type |
| `SERVER_SECURITY_HEADERS` | `false` | Adds HSTS / `X-Frame-Options` / CSP-style headers |
| `SERVER_CORS_ALLOW_ORIGINS` | — | Comma-separated origins, or `*` for any |
| `SERVER_DIRECTORY_LISTING` | `false` | Browsable directory index |
| `SERVER_INDEX_FILES` | `index.html` | Index files for trailing-slash requests |
| `SERVER_FALLBACK_PAGE` | — | SPA fallback page, served with HTTP 200 (see below) |
| `SERVER_HEALTH` | `false` | Enables a `/health` endpoint |

Example — enable compression tuning, security headers and CORS:

```bash
docker run --rm -p 8080:80 -v "$PWD/dist:/web:ro" \
  -e SERVER_COMPRESSION_STATIC=true \
  -e SERVER_SECURITY_HEADERS=true \
  -e SERVER_CORS_ALLOW_ORIGINS='*' \
  zzci/web
```

### Single Page Applications (React / Vue / etc.)

Serve `index.html` (with a `200` status) for unknown client-side routes:

```bash
docker run --rm -p 8080:80 -v "$PWD/dist:/web:ro" \
  -e SERVER_FALLBACK_PAGE=/web/index.html \
  zzci/web
```

> The fallback path is **not** relative to the root — give the full container path.

### Custom error pages

SWS automatically serves `404.html` and `50x.html` from the document root when
present. Override the paths with `SERVER_ERROR_PAGE_404` / `SERVER_ERROR_PAGE_50X`.

### CLI flags

Any arguments after the image name are forwarded to `static-web-server`:

```bash
docker run --rm -p 8080:80 -v "$PWD:/web:ro" \
  zzci/web --directory-listing true --directory-listing-order 6

# See every available flag
docker run --rm zzci/web --help
```

### TOML config file

For headers, redirects, rewrites, virtual hosts and other advanced features,
mount a config file and point `SERVER_CONFIG_FILE` at it:

```bash
docker run --rm -p 8080:80 \
  -v "$PWD/dist:/web:ro" \
  -v "$PWD/config.toml:/etc/sws/config.toml:ro" \
  -e SERVER_CONFIG_FILE=/etc/sws/config.toml \
  zzci/web
```

A fully commented starting point is provided in
[`config.example.toml`](./config.example.toml). Reference:
<https://static-web-server.net/configuration/config-file/>.

## docker compose

The included [`docker-compose.yml`](./docker-compose.yml) is the recommended
setup: it mounts `./dist` to `/web` and drives everything through `SERVER_*`
environment variables (compression, security headers, health check, …).

```bash
docker compose up -d          # serves ./dist on http://localhost:8080
WEB_PORT=3000 docker compose up -d   # override the published port
```

## Entrypoint behaviour

[`docker-entrypoint.sh`](./docker-entrypoint.sh) decides what to run:

- `docker run zzci/web sh` — drops you into a shell (`sh` / `ash` recognised).
- `docker run zzci/web <args>` — runs `static-web-server <args>`.
- `docker run zzci/web` — starts SWS with the `SERVER_HOST` / `SERVER_PORT` /
  `SERVER_ROOT` / `SERVER_LOG_LEVEL` defaults shown above.

## Development

Build multi-arch locally with Buildx:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t zzci/web .

# Pin a different SWS release
docker build --build-arg SWS_VERSION=2.43.0 -t zzci/web .
```

Images are published by the [`build-push-web`](./.github/workflows/docker.yml)
GitHub Actions workflow (manual dispatch and a monthly schedule).

## License

MIT. Static Web Server is distributed under its own
[MIT/Apache-2.0 license](https://github.com/static-web-server/static-web-server).
