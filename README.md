# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and RustDesk self-hosted server components.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**.

## What this project ships

Release Please owns one semantic version for the stack. A release publishes:

```text
ghcr.io/nomed/rustdesk-web-stack/web:<version>
oci://ghcr.io/nomed/rustdesk-web-stack/charts/rustdesk-stack:<version>
GitHub release v<version>
```

The stack version is independent from the RustDesk upstream server version.

Install the Helm chart directly from GHCR:

```bash
helm install rustdesk \
  oci://ghcr.io/nomed/rustdesk-web-stack/charts/rustdesk-stack \
  --version <version>
```

## Stack architecture

```text
Browser
   |
   | HTTPS / WSS
   v
Kubernetes Gateway API
   |-- /          -> web (Caddy + Flutter assets)
   |-- /ws/id     -> hbbs :21118
   `-- /ws/relay  -> hbbr :21119

Native RustDesk clients
   |-- TCP/UDP 21116 -> hbbs
   `-- TCP     21117 -> hbbr
```

The Helm chart does **not** install a Gateway controller. Envoy Gateway and Traefik are reference implementations; any conformant Gateway API controller may be used.

## Helm chart

`charts/rustdesk-stack` deploys:

- the project-owned web image;
- `hbbs` and its persistent data;
- `hbbr`;
- services for native and WebSocket ports;
- optional Gateway/HTTPRoute resources;
- optional shared server key injection through an existing Kubernetes Secret.

The default server image is pinned to the latest verified released RustDesk Server version rather than an upstream `latest` tag.

## Web build

`build/build-baseline-image.sh` uses pinned upstream web-capable sources/tooling to generate the RustDesk Web assets, extracts those assets, and then packages the released runtime with **Caddy**.

`build/build-web.sh` remains the experimental track for reconstructing the Web Client from current official RustDesk sources.

## Repository governance

Read `AGENTS.md` and `.context/README.md` before meaningful work. Material architecture, deployment and release decisions are recorded under `.context/decisions/`; accepted records are immutable and must be superseded rather than edited.

## Versioning and releases

Conventional commits drive Release Please. A release PR updates:

- `CHANGELOG.md`;
- `.release-please-manifest.json`;
- `charts/rustdesk-stack/Chart.yaml` (`version` and `appVersion`).

When the Release Please PR is merged, the release workflow creates the GitHub release and publishes both OCI artifacts using the same stack version.

A recreated Release Please PR must preserve the generated body and `autorelease: pending` metadata or the merge may not be recognized as a release.

## Upstream relationship

RustDesk server containers are consumed from official upstream releases. The historical upstream Helm PR `rustdesk/rustdesk-server#399` is treated as reference material only; this project maintains its own full-stack chart.

## License

This repository contains deployment/build tooling and packages RustDesk-derived artifacts. RustDesk and upstream components retain their respective licenses and copyright notices.
