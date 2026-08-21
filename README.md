# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and the RustDesk self-hosted server components required to use it.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**. RustDesk is developed upstream at https://github.com/rustdesk/rustdesk.

## Status

**Early bootstrap / proof of concept.**

RustDesk still actively maintains browser-specific application code, and its main GitHub Actions workflow still contains a `build-rustdesk-web` job. However, that job is currently disabled (`if: False`) and the current OSS tree no longer ships the `flutter/web` scaffold that the disabled job assumes is present.

This repository therefore separates the build into two pinned inputs:

1. the current official RustDesk source revision, which remains authoritative for the Dart/Rust application code;
2. a pinned RustDesk-derived historical web scaffold used only to restore `flutter/web` (HTML/bootstrap/JS build sources).

The historical scaffold's vendored codec/runtime binaries are discarded. The build downloads RustDesk's official `web_deps.tar.gz`, rebuilds the JavaScript bridge against the pinned current RustDesk source, and then runs the Flutter web build.

## Goals

- build the RustDesk Web Client from a pinned upstream revision;
- package the generated Flutter Web assets as an OCI image;
- expose the web application through a standard HTTP server;
- deploy `hbbs` and `hbbr` with the WebSocket endpoints required by browser clients;
- provide a Kubernetes/Helm deployment path;
- keep upstream RustDesk source code out of this repository whenever possible;
- make upstream version bumps explicit and reproducible.

## Non-goals

- fork or rebrand RustDesk;
- replace the RustDesk protocol or server;
- claim compatibility beyond what is verified by CI and the project test matrix.

## Planned architecture

```text
Browser
   |
   | HTTPS / WSS
   v
Ingress / reverse proxy
   |-----------------------|
   |                       |
   v                       v
rustdesk-web             hbbs / hbbr
(static Flutter app)     WebSocket endpoints
                           |
                           v
                    RustDesk remote agent
```

## Repository layout

```text
build/                  Web Client build tooling
container/              Runtime container for generated web assets
charts/rustdesk-web/    Helm chart
examples/               Example values/configuration
docs/                   Architecture and operational notes
.github/workflows/       CI/build automation
```

## Reproducible web build

Pinned build inputs live in `build/upstream.env`.

The build implemented by `build/build-web.sh`:

1. checks out the pinned official RustDesk revision;
2. applies the Flutter patch used by RustDesk upstream when required;
3. restores only `flutter/web` from the pinned historical scaffold;
4. removes vendored historical web runtime binaries;
5. downloads and extracts RustDesk's official `web_deps.tar.gz`;
6. rebuilds the web JavaScript bridge (`ts-proto`, TypeScript, Vite 2.8);
7. runs `flutter pub get` and `flutter build web --release`;
8. writes provenance to `dist/web/BUILD-INFO.txt`.

The GitHub Actions workflow uploads the web artifact and, on `main`, builds/publishes the static runtime image to GHCR.

## Roadmap

1. Get the reconstructed Web Client build green in CI.
2. Validate a real browser-to-agent session against self-hosted `hbbs`/`hbbr`.
3. Publish a minimal static web container with a tested tag/version policy.
4. Complete Helm templates for the web client plus `hbbs`/`hbbr` services.
5. Add HTTPS/WSS ingress examples and an end-to-end browser connection test.

## License and upstream components

This repository contains deployment/build tooling. RustDesk and any upstream artifacts retain their respective licenses and copyright notices. Before redistributing generated RustDesk artifacts, review the applicable upstream license and notices.
