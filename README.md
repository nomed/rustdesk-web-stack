# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and the RustDesk self-hosted server components required to use it.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**. RustDesk is developed upstream at https://github.com/rustdesk/rustdesk.

## Status

**Early bootstrap / proof of concept.**

RustDesk still contains and actively changes Web Client-specific Dart code, but the current OSS source tree no longer contains the historical `flutter/web` scaffold. Upstream also still carries a disabled (`if: False`) `build-rustdesk-web` workflow that assumes `flutter/web/js` exists, so that workflow no longer matches the public source tree as-is.

The official `web_deps.tar.gz` referenced by RustDesk was verified in CI: it contains codec/runtime dependencies (`ogvjs`, `libopus`, `yuv-canvas`) only, not `index.html` or the JavaScript/TypeScript client scaffold.

This project therefore builds from three explicit, pinned inputs:

```text
official RustDesk source (current Dart/Rust application)
        |
historical RustDesk-derived flutter/web scaffold
        |
official RustDesk web_deps.tar.gz (codec/wasm assets)
        |
        v
regenerate JS bridge against current RustDesk source
        |
        v
flutter build web --release
        |
        +--> CI artifact: rustdesk-web-<upstream-ref>
        |
        +--> ghcr.io/nomed/rustdesk-web-stack
```

The historical scaffold currently comes from a pinned revision of `pmietlicki/rustdesk-web-client`, which preserves the old RustDesk `flutter/web` tree and carries the same upstream AGPL license. Only `flutter/web` is overlaid; Dart/Rust application code stays on the pinned official RustDesk revision. Vendored codec binaries from the historical tree are discarded and replaced by the official RustDesk dependency bundle.

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

All source inputs are pinned in `build/upstream.env`.

Prerequisites are Git, Flutter at the pinned version, Node/npm, Python and Yarn. Then run:

```bash
bash build/build-web.sh
```

The generated static application is written to `dist/web`.

## Provenance and build strategy

The build intentionally does **not** copy the entire historical fork. It:

1. checks out the pinned official `rustdesk/rustdesk` revision;
2. checks out the pinned historical RustDesk-derived scaffold;
3. overlays only `flutter/web`;
4. removes codec binaries inherited from that scaffold;
5. extracts RustDesk's official `web_deps.tar.gz`;
6. regenerates the JavaScript bridge against the current RustDesk source;
7. runs `flutter build web --release`.

This behavior is deliberately fail-fast. Compatibility between the historical scaffold and current RustDesk code must be demonstrated by CI before an OCI image is published.

## Roadmap

1. Obtain a green Web Client build in CI from the pinned inputs.
2. Pin/checksum every downloaded external artifact.
3. Publish a minimal static web container to GHCR.
4. Add Helm templates for the web client plus `hbbs`/`hbbr` services.
5. Add HTTPS/WSS ingress examples and an end-to-end browser connection test.

## License and upstream components

This repository contains deployment/build tooling. RustDesk and RustDesk-derived scaffold code retain their respective licenses and copyright notices. Before redistributing generated RustDesk artifacts, review the applicable upstream license and notices.
