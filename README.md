# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and the RustDesk self-hosted server components required to use it.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**. RustDesk is developed upstream at https://github.com/rustdesk/rustdesk.

## Status

**Early bootstrap / proof of concept.**

RustDesk still contains and actively changes Web Client-specific Dart code, but the current OSS source tree no longer contains the historical `flutter/web` scaffold. Upstream also still carries a disabled (`if: False`) `build-rustdesk-web` workflow that assumes `flutter/web/js` exists, so current public source and that workflow no longer match as-is.

The repository therefore separates two tracks.

### 1. Baseline — primary delivery path

A known web-capable RustDesk-derived source and its packaging toolchain are pinned by commit in `build/baseline.env`. CI builds the complete Nginx image, extracts the generated static assets for inspection, and publishes to GHCR only after a successful `main` build.

```text
pinned web-capable RustDesk source
        |
pinned packaging toolchain
        |
JS/TS + Rust/WASM + Flutter Web
        |
        +--> dist/web CI artifact
        |
        +--> ghcr.io/nomed/rustdesk-web-stack
```

The baseline currently uses:

- `MonsieurBiche/rustdesk-web-client@525b5e561faf824850c71500adf463e4e0a504d4` as the web-capable RustDesk-derived source;
- `pmietlicki/docker-rustdesk-web-client@53b466586ba1de91ae489cd55e33bf99968e97c8` as the pinned reproducible packaging recipe;
- Flutter `3.22.1`;
- Rust `1.97.0` with the WebAssembly target;
- WSS enabled.

### 2. Current RustDesk port — experimental

`build/build-web.sh` tracks the separate effort to reconstruct a Web Client from a current pinned `rustdesk/rustdesk` revision. CI already established that RustDesk's official `web_deps.tar.gz` contains codec/runtime dependencies only and does **not** contain the missing `flutter/web` scaffold.

This track must become independently green before it can replace the baseline.

## Goals

- provide a working browser client image first;
- keep every external source pinned and reviewable;
- package generated Flutter Web assets as an OCI image;
- expose API and WebSocket paths through one HTTP(S) endpoint;
- deploy the web client plus `hbbs`/`hbbr` through Helm;
- add HTTPS/WSS ingress examples and end-to-end validation;
- progressively move the web build toward current RustDesk source without pretending the current OSS tree is directly buildable today.

## Planned architecture

```text
Browser
   |
   | HTTPS / WSS
   v
Ingress / reverse proxy
   |
   v
rustdesk-web
   |-- /api/     --> RustDesk API/backend
   |-- /ws/id    --> hbbs :21118
   `-- /ws/relay --> hbbr :21119
                         |
                         v
                  RustDesk remote agent
```

## Repository layout

```text
build/baseline.env            pinned delivery inputs
build/build-baseline-image.sh primary image build
build/upstream.env            current-RustDesk experimental inputs
build/build-web.sh            current-RustDesk experimental build
container/                    runtime/container support
charts/rustdesk-web/          Helm chart
examples/                     deployment examples
docs/                         architecture and operational notes
.github/workflows/            CI/build automation
```

## Build the baseline

Prerequisites: Git and Docker.

```bash
bash build/build-baseline-image.sh
```

Outputs:

```text
rustdesk-web-stack:ci   local OCI image
dist/web/               extracted static web application
```

## CI publication

Pull requests build and validate the baseline without publishing it. A successful build on `main` publishes:

```text
ghcr.io/nomed/rustdesk-web-stack:latest
ghcr.io/nomed/rustdesk-web-stack:web-<source-sha>
```

## Current RustDesk investigation

The disabled upstream web job historically performed a JavaScript/Vite build followed by `flutter build web --release`. The current public RustDesk tree no longer contains `flutter/web`. CI also verified that the official dependency archive contains `ogvjs`, `libopus`, `yuv-canvas` and related runtime assets, but not the missing client scaffold.

The experimental current-source build is retained so that this gap can be closed explicitly and tested rather than hidden behind an unverified Dockerfile.

## Roadmap

1. Get the pinned baseline image green in our CI and publish it to GHCR.
2. Wire the Helm chart to the published image and add runtime proxy settings.
3. Add `hbbs` and `hbbr`, including ports `21118`/`21119`.
4. Add HTTPS/WSS Ingress examples and an end-to-end connection smoke test.
5. Continue the current-RustDesk web port and promote it only when it passes the same tests.

## License and provenance

RustDesk and the RustDesk-derived web client are AGPL-licensed upstream components. This repository does not claim authorship of those components. External source and packaging revisions used by CI are explicit and pinned; generated artifacts retain the applicable upstream license and notices.
