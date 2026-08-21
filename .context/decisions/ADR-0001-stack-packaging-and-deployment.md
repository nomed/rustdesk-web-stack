# ADR-0001: Stack packaging and deployment model

Status: Accepted
Date: 2026-08-21
Governing issue: #9

## Context

The project must ship a reproducible RustDesk browser client together with a maintainable Kubernetes deployment for the self-hosted RustDesk server components. The upstream RustDesk server project provides container images and historical/WIP Helm work, but no current maintained full-stack Helm chart. The web client build path also requires project-owned packaging.

## Decision

1. Release Please owns one semantic version for this repository's stack artifacts.
2. A release publishes:
   - `ghcr.io/nomed/rustdesk-web-stack/web:<version>`;
   - `oci://ghcr.io/nomed/rustdesk-web-stack/charts/rustdesk-stack:<version>`;
   - GitHub tag/release `v<version>`.
3. The Helm chart is named `rustdesk-stack` and deploys the complete stack: web client, `hbbs`, `hbbr`, persistence/secrets and networking.
4. RustDesk server image/version is configured and pinned independently from the stack version.
5. The web runtime uses Caddy rather than NGINX.
6. Kubernetes Gateway API is the preferred HTTP/WSS exposure contract. The chart does not install or require a specific Gateway controller; Envoy Gateway and Traefik are reference implementations.
7. Native RustDesk TCP/UDP endpoints remain independently exposable through Kubernetes Services; TCPRoute/UDPRoute may be added optionally when controller support is appropriate.
8. Upstream `rustdesk/rustdesk-server#399` is reference material only, not a Helm dependency.
9. Upstream source and tooling inputs used for released artifacts must be pinned and reviewable; `latest` is not a release default.

## Consequences

- Stack and upstream RustDesk versions evolve independently.
- Cluster operators retain control over GatewayClass/controller choice.
- The chart owns more server deployment logic but avoids depending on an abandoned upstream chart.
- Release validation must lint/template the full stack and publish both OCI artifacts atomically from the same Release Please version.
