# Starknet Privacy Toolkit — Dependencies

This document explains how to install the toolchain using the `Makefile` and helper scripts. Installation is kept separate from project workflows; use the Makefile for installs, and follow the original flow in `BADGE_SETUP.md` and `README.md` for everything else.

---

## Automatic Install

Install all required tools at once:

```bash
make install-all
```

This installs:
- `sncast` — Starknet Foundry CLI (accounts, declare/deploy)
- `nargo` — Noir CLI (ZK circuits)
- `scarb` — Cairo package manager
- `bb` — Barretenberg CLI (proof generation)

Notes:
- If a prebuilt `bb` binary is unavailable, the installer falls back to `bbup` and pins the version automatically.
- Scripts only install dependencies. Use the Makefile and guides for building, proving, and deploying.

---

## Included Scripts

### `scripts/setup.sh`
Installs system/toolchain dependencies only, then points you to Makefile targets.

```bash
./scripts/setup.sh
```

### `scripts/verify.sh`
Verifies scripts, Makefile targets, and repository structure.

```bash
./scripts/verify.sh
```

### `scripts/uninstall.sh`
Removes installed CLIs and cleans caches. Add `--remove-rust` to also remove Rust toolchains.

```bash
./scripts/uninstall.sh
./scripts/uninstall.sh --remove-rust  # optional
```

---

For full setup and version pinning, see `BADGE_SETUP.md` and `README.md`.