# rustdesk-web-stack Context System

`.context/` is the durable operating memory for humans and coding agents working on this repository.

## Source precedence

1. explicit human instruction in the current task;
2. accepted decisions in `.context/decisions/`;
3. project architecture and standards;
4. root and nearest `AGENTS.md`;
5. governing GitHub issue and pull request;
6. latest handoff;
7. session records;
8. temporary notes.

A session, handoff, issue comment or pull-request discussion does not change architecture by itself. Material decisions must be promoted to an ADR and accepted through human review.

## Structure

- `manifest.yaml`: machine-readable precedence, record and release policy.
- `decisions/`: architectural decision records. Accepted records are immutable.
- `sessions/`: chronological implementation/evidence records.
- `handoffs/`: durable continuation notes between people or agents.

## Required workflow

Before meaningful implementation: read the manifest and AGENTS rules, identify the governing issue, load relevant accepted decisions, and inspect pinned upstream evidence rather than assuming current defaults.

After meaningful work: record a session, link the governing issue/PR, list checks performed, record unresolved risks, and create a handoff when the work is not complete.
