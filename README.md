# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and the RustDesk self-hosted server components required to use it.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**. RustDesk is developed upstream at https://github.com/rustdesk/rustdesk.

## Status

**Early bootstrap / proof of concept.**

The RustDesk upstream repository still contains and actively maintains Web Client code, but its `build-rustdesk-web` GitHub Actions job is currently disabled (`if: False`). This repository reproduces that upstream build recipe with pinned inputs and packages the resulting static client as an OCI image.

Current CI target:

```text
pinned RustDesk source
        |
        v
flutter/web/js build
        |
        v
web_deps.tar.gz
        |
        v
flutter build web --release
        |
        +--> CI artifact: rustdesk-web-<upstream-ref>
        |
        +--> ghcr.io/nomed/rustdesk-web-stack
```

The container is published only from a successful `main` build. Pull requests build and validate the web client without publishing an image.

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

## Build

The build is intentionally pinned in `build/upstream.env`.

Prerequisites are Git, Flutter at the pinned version, Node/npm and Yarn. Then run:

```bash
./build/build-web.sh
```

The generated static application is written to `dist/web`.

## Upstream build note

RustDesk upstream keeps a disabled `build-rustdesk-web` job in `.github/workflows/flutter-build.yml`. Its recipe builds the JavaScript bridge under `flutter/web/js`, downloads the upstream `web_deps.tar.gz` bundle, applies the Flutter patch required by the pinned SDK where necessary, and finally runs:

```bash
cd flutter
flutter build web --release
```

This project mirrors that sequence instead of treating a plain `flutter build web` as sufficient.

## Roadmap

1. Reproduce the upstream disabled Web Client build locally and in CI.
2. Pin the RustDesk commit and all external build inputs.
3. Publish a minimal static web container.
4. Add Helm templates for the web client plus `hbbs`/`hbbr` services.
5. Add HTTPS/WSS ingress examples and an end-to-end browser connection test.

## License and upstream components

This repository contains deployment/build tooling. RustDesk and any upstream artifacts retain their respective licenses and copyright notices. Before redistributing generated RustDesk artifacts, review the applicable upstream license and notices.
