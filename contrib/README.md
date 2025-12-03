# Contrib Guidelines (ADR-style)

This folder hosts numbered contribution records (lightweight ADRs) documenting non-trivial repository changes and decisions.

- Naming: `0001-<short-kebab-title>.md`, then `0002-...`, sequential.
- Language: English.
- Scope: Each record should explain context, decision, implementation, versions (if relevant), validation, and suggested commit structure.
- Status: Use `Accepted`, `Proposed`, or `Deprecated`.
- Date: `YYYY-MM-DD`.

Template (copy for new records):

```markdown
# <NNNN>: <Title>

Status: <Accepted|Proposed|Deprecated>
Date: YYYY-MM-DD

## Context

<Background and problem statement>

## Decision

<Key decisions made>

## Implementation

<Files, scripts, modules touched; how it was done>

## Pinned Versions (optional)

- <tool>: <version>

## Validation

<How it was tested; commands or scenarios>

## Commit Structure (one file per commit)

1. <subject> — <file>

## Notes

<Additional considerations>
```

Quick start:

```bash
# Generate a new record with the helper script
contrib/new-record.sh "Title in Kebab Case" "Status" 
# Example:
contrib/new-record.sh "deploy-onchain-flow" "Proposed"
```