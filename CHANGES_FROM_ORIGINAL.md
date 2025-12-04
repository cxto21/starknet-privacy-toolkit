# Starknet Privacy Toolkit — Changes From Original Template

This document records, with traceability, every fix, addition, and adjustment made to align this fork with the original Oz Kit flow and to restore a clean, reproducible developer experience.

It also provides an exact commit plan (one commit per file where possible) so changes are easy to review and revert individually.

Last updated: 2025-12-03

---

## Summary of What Was Fixed

- Restored the original step-by-step flow in `BADGE_SETUP.md` (including the missing Step 4: Starknet Foundry) and renumbered subsequent steps accordingly.
- Clarified that scripts only install dependencies; workflows are driven by the Makefile and original setup guides.
- Aligned `README.md` with the restored flow and corrected paths, including the API entrypoint and web index path.
- Repaired and hardened installers: `install-*.sh` scripts plus a single `setup.sh` that clearly communicates “deps-only.”
- Added a verification script and refined the uninstall script to be idempotent and transparent.
- Fixed API pathing and environment detection in `api/server.ts` to use repo-relative paths and locate `garaga` either from a local venv or from the user PATH.
- Completed a full Noir → Barretenberg → Garaga pipeline, generated calldata, and stored it in `calldata.txt` for reproducibility.
- Ensured the verifier project builds by adding the Cairo entry file `donation_badge_verifier/src/lib.cairo`.
- Added `package.json` script `api` for running the proof API (`bun run api`).

---

## Toolchain Versions (Pinned/Validated)

- Noir (`nargo`): 1.0.0-beta.1
- Barretenberg (`bb`): 0.67.0 (fallback to `bbup` when prebuilt is missing)
- Scarb: 2.9.2
- Starknet Foundry (`sncast`): 0.53.0
- Garaga (PyPI): 0.15.5

Notes:
- Installers attempt to download prebuilt binaries first, then gracefully fall back to source or alternate installers.
- The `setup.sh` script installs dependencies only and instructs users to use Makefile targets and the setup guides for the full workflow.

---

## Detailed Changes and Steps Per Area

### 1) Documentation Flow Corrections

- Restored the original Oz Kit flow in `BADGE_SETUP.md` starting from Step 2, and added the missing Step 4 (Install Starknet Foundry). Renumbered subsequent steps. Clarified that any Cargo reference is contextual (not core to the flow).
- Updated `README.md` to:
  - Point to the correct paths (`src/web/index.html`).
  - Use the repository-relative API entrypoint (`api/server.ts`).
  - Include the command to run the API server: `bun run api`.
- Translated and reframed `DEPENDENCIES.md` to English with a “deps-only” scope and clear guidance on verification and uninstall.

What I actually did:
- Compared local guides with the original template, noted the missing Foundry step, restored and renumbered steps.
- Audited references to scripts vs Makefile targets; redirected users to Makefile for workflows.
- Replaced hard-coded or external paths with repo-relative ones in documentation notes.

### 2) Installers and Setup

- Reworked installers to be idempotent and resilient:
  - `scripts/install-noir.sh` downloads/pins `nargo` v1.0.0-beta.1; falls back to `cargo build` if needed.
  - `scripts/install-scarb.sh` pins Scarb v2.9.2.
  - `scripts/install-barretenberg.sh` attempts prebuilt `bb` first, then installs `bbup`, and pins `bb 0.67.0` through `bbup` if needed.
  - `scripts/install-sncast.sh` pulls a prebuilt Starknet Foundry archive and extracts `sncast` v0.53.0.
- `scripts/setup.sh`: clarifies “dependencies only”; ensures system prerequisites; installs above tools and `garaga==0.15.5` in user space (`~/.local/bin`).
- `scripts/uninstall.sh`: removes toolchain pieces cleanly; optional `--remove-rust` step; shows a verification summary.
- `scripts/verify.sh`: validates presence/permissions of scripts, Makefile targets, README sections, and key project structure.

What I actually did:
- Ran `./scripts/uninstall.sh` to validate clean removal.
- Ran `make install-all` and confirmed versions; patched Barretenberg install to use `bbup` when prebuilt binaries 404.
- Verified installer idempotency by re-running installers and checking versions did not drift.
- Executed `./scripts/verify.sh` to ensure scripts, Makefile, and docs are consistent.

### 3) API Server and ZK Pipeline

- `api/server.ts` now:
  - Uses `process.cwd()` + `path.join` to resolve repo-relative paths.
  - Writes `Prover.toml` into `zk-badges/donation_badge`.
  - Detects `garaga` from `garaga-env/bin/garaga` (if present) or from PATH (typical `~/.local/bin/garaga`).
  - Runs `nargo execute witness`, `bb prove_ultra_keccak_honk`, `bb write_vk_ultra_keccak_honk`, and `garaga calldata` sequentially.
  - Returns `{ calldata, commitment, success: true }` on success.
  - Listens on `http://localhost:3001`.
- `package.json`: added `