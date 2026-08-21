# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and the RustDesk self-hosted server components required to use it.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**. RustDesk is developed upstream at https://github.com/rustdesk/rustdesk.

## Status

**Early bootstrap / proof of concept.**

RustDesk still contains Web Client-specific application code and receives Web Client fixes, but the current OSS tree no longer contains the historical `flutter/web` scaffold. At the same time, upstream still carries a disabled (`if: False`) `build-rustdesk-web` workflow that assumes `flutter/web/js` already exists. The upstream workflow and current source tree therefore no longer match exactly.

This project makes that mismatch explicit and reconstructs a reproducible build from pinned RustDesk source plus RustDesk's official `web_deps.tar.gz` bundle.

Current CI target:

```text
pinned RustDesk source
        |
        +--> official web_deps.tar.gz
        |        |
        |        +--> bootstrap flutter/web
        |                 |
        |                 +--> build JS when source is present
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

- build the RustDesk Web Client from pinned, reviewable upstream inputs;
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

The build inputs are pinned in `build/upstream.env`.

Prerequisites are Git, Flutter at the pinned version, Node/npm and Yarn. Then run:

```bash
bash build/build-web.sh
```

The generated static application is written to `dist/web`.

## Upstream build note

RustDesk upstream keeps a disabled `build-rustdesk-web` job in `.github/workflows/flutter-build.yml`. That job still assumes the historical `flutter/web/js` directory exists before downloading `web_deps.tar.gz`, while the current OSS source tree no longer includes `flutter/web`.

`rustdesk-web-stack` therefore bootstraps `flutter/web` from the official RustDesk web dependency bundle first, then builds the JavaScript layer only when its source is actually present, before running:

```bash
cd flutter
flutter build web --release
```

This behavior is deliberately fail-fast: if the official bundle does not provide a usable Flutter web scaffold, CI stops and exposes its contents rather than publishing a misleading image.

## Roadmap

1. Reproduce a working Web Client build in CI from pinned upstream inputs.
2. Pin and checksum all external build inputs.
3. Publish a minimal static web container.
4. Add Helm templates for the web client plus `hbbs`/`hbbr` services.
5. Add HTTPS/WSS ingress examples and an end-to-end browser connection test.

## License and upstream components

This repository contains deployment/build tooling. RustDesk and any upstream artifacts retain their respective licenses and copyright notices. Before redistributing generated RustDesk artifacts, review the applicable upstream license and notices.
