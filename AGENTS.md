# rustdesk-web-stack Agent Operating Rules

These instructions apply to humans and coding agents working in this repository.

## Before acting

1. Read `.context/manifest.yaml` and `.context/README.md`.
2. Identify the governing GitHub issue and linked pull request.
3. Load accepted decisions relevant to the task.
4. When continuing previous work, read the latest relevant handoff/session.
5. Surface conflicts, missing evidence and upstream uncertainty instead of guessing.

## Source precedence

When sources conflict, follow `.context/manifest.yaml`. Current explicit human instruction and accepted architectural decisions outrank repository guidance, issue discussion, sessions and temporary notes.

## Required workflow

- Every meaningful change must be governed by a GitHub issue.
- Work on a focused branch and pull request; do not implement directly on `main`.
- Record material architecture, deployment, security, compatibility or release/packaging decisions as an ADR before or with implementation.
- Accepted ADRs are immutable; supersede them with a new record.
- Pin upstream source/image/tooling versions used for released artifacts. Do not silently track `latest` or an upstream default branch.
- Record meaningful implementation work in `.context/sessions/` and create a handoff when continuation is expected.
- Conventional commits are required because Release Please owns stack versioning.

## Project boundaries

- This repository packages and deploys RustDesk-derived components; it is not an official RustDesk project.
- Keep upstream source code out of this repository whenever practical. Prefer pinned upstream references plus reproducible build/packaging logic.
- The stack version is independent from RustDesk upstream versions.
- `rustdesk-stack` is the deployment product: web client, `hbbs`, `hbbr`, networking, persistence and secrets.
- The Helm chart must not install or depend on a specific ingress/gateway controller. Kubernetes Gateway API is the preferred L7 contract.
- Native RustDesk TCP/UDP exposure must remain usable independently from the HTTP/WSS gateway path.

## Release contract

A Release Please release publishes the same stack version for:

- `ghcr.io/nomed/rustdesk-web-stack/web:<version>`;
- `oci://ghcr.io/nomed/rustdesk-web-stack/charts/rustdesk-stack:<version>`;
- GitHub tag/release `v<version>`.

The chart pins/configures its RustDesk server version separately from the stack version.

## Completion evidence

At the end of meaningful work record: governing issue/PR, files changed, tests/checks, upstream evidence, decisions applied, unresolved risks and next actions.