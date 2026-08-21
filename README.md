# rustdesk-web-stack

Unofficial, reproducible packaging and deployment stack for the RustDesk Web Client and the RustDesk self-hosted server components required to use it.

> [!IMPORTANT]
> This project is **not affiliated with, sponsored by, or endorsed by RustDesk**. RustDesk is developed upstream at https://github.com/rustdesk/rustdesk.

## Status

**Early bootstrap / proof of concept.**

RustDesk still actively maintains browser-specific application code, and its main GitHub Actions workflow still contains a `build-rustdesk-web` job. However, that job is currently disabled (`if: False`) and the current OSS tree no longer ships the `flutter/web` scaffold that the disabled job assumes is present.

This repository keeps the current-source reconstruction as an experimental track and uses a pinned, known web-capable RustDesk baseline for the deployable OCI artifacts.

## Release artifacts

Releases are managed by Release Please and use one semantic version across the repository, container image and Helm chart.

For a release such as `v0.1.0` the workflow publishes:

```text
ghcr.io/nomed/rustdesk-web-stack:0.1.0
ghcr.io/nomed/rustdesk-web-stack:v0.1.0
ghcr.io/nomed/rustdesk-web-stack:latest
oci://ghcr.io/nomed/charts/rustdesk-web --version 0.1.0
```

Install the Helm chart directly from GHCR:

```bash
helm install rustdesk-web \
  oci://ghcr.io/nomed/charts/rustdesk-web \
  --version 0.1.0
```

By default the chart uses the image version matching `Chart.appVersion`. Override `image.tag` only when intentionally testing a different image.

## Goals

- build the RustDesk Web Client from pinned, reviewable source inputs;
- package the generated Flutter Web assets as an OCI image;
- publish the Helm chart as an OCI artifact to GHCR;
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
.github/workflows/       CI, Release Please and publication automation
```

## Build tracks

`build/build-baseline-image.sh` is the release path. Its inputs are pinned in `build/baseline.env` and it produces the web runtime image plus `dist/web`.

`build/build-web.sh` is the experimental current-RustDesk reconstruction. Its inputs are pinned in `build/upstream.env`; it restores the historical `flutter/web` scaffold and attempts to regenerate it against current official RustDesk code.

## Versioning

Release Please owns the repository version. Conventional commits drive version bumps and the release PR updates:

- `CHANGELOG.md`;
- `.release-please-manifest.json`;
- `charts/rustdesk-web/Chart.yaml` (`version` and `appVersion`).

When the Release Please PR is merged, the same release workflow creates the GitHub release and publishes both the versioned container image and the Helm chart to GHCR.

A release PR must retain Release Please's `autorelease: pending` metadata. If a PR has to be recreated manually from the generated release branch, restore that label before merging it; otherwise Release Please will treat the merge as an ordinary commit and generate the next release proposal instead of tagging the merged version.

## Roadmap

1. Validate the pinned Web Client baseline and OCI release pipeline.
2. Validate a real browser-to-agent session against self-hosted `hbbs`/`hbbr`.
3. Complete Helm templates for the web client plus `hbbs`/`hbbr` services.
4. Add HTTPS/WSS ingress examples and an end-to-end browser connection test.
5. Continue the current-RustDesk reconstruction until it can replace the baseline release source.

## License and upstream components

This repository contains deployment/build tooling. RustDesk and any upstream artifacts retain their respective licenses and copyright notices. Before redistributing generated RustDesk artifacts, review the applicable upstream license and notices.
