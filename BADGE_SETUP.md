# 🏅 Verified Donor Badge System Setup Guide

This guide explains how to set up the Verified Donor Badge system.

## Tech Stack

- **Noir** `1.0.0-beta.1` + Poseidon dependency
- **Barretenberg** `0.67.0` (Ultra Keccak Honk backend)
- **Garaga** `0.15.5` for Cairo verifier generation
- **Scarb** `2.9.2` (Cairo build)
- **Starknet Foundry** (`sncast`, `snforge`) for declares/deploys
- **Starkli** for manual invocations
- **Bun + TypeScript** for frontend/API

> **Note**: The automated installation will handle most of these prerequisites.

---

## Step 1: Install Required Tools

### Option A: Automated Installation

1. Run the `setup.sh` script to install all required tools and dependencies:

```bash
./scripts/setup.sh
```

This script will:
- Install system dependencies (e.g., `libc++1`, `build-essential`, `python3.10-dev`)
- Install Rust and Cargo
- Install Scarb
- Install Noir CLI
- Install Barretenberg (bb)
- Install Garaga (Python CLI)

2. **Verify the installation**
   ```bash
   make install-all
   ```

### Option B: Manual Installation

Follow these steps to install each tool manually:

#### 1. Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y libc++1 build-essential python3.10-dev
python3.10 -m pip install --upgrade pip setuptools wheel
```

#### 2. Install Rust and Cargo

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | RUSTUP_INIT_SKIP_PATH_CHECK=yes sh -s -- -y
source $HOME/.cargo/env
```

Note: Rust/Cargo are required only because tooling like `noirup`/`bbup` ship prebuilt binaries and occasionally build helpers that rely on Rust's environment. We do not compile Rust code in this project.

#### 3. Install Scarb

```bash
./scripts/install-scarb.sh
```

#### 4. Install Noir CLI

```bash
./scripts/install-noir.sh
```

#### 5. Install Barretenberg (bb)

```bash
./scripts/install-barretenberg.sh
```

#### 6. Install Garaga (Python CLI)

```bash
python3.10 -m pip install --user garaga==0.15.5
```

---

## Step 2: Compile the Noir Circuit

Navigate to the `zk-badges/donation_badge` directory and compile the Noir circuit:

```bash
cd zk-badges/donation_badge
nargo compile
nargo test
```

Expected output:

```
[donation_badge] Compiling...
[donation_badge] Testing...
test test_valid_silver_badge ... ok
test test_valid_gold_badge ... ok
```

---

## Step 3: Generate Proof and Verification Key

```bash
# Execute circuit with inputs to generate witness
nargo execute witness

# Generate proof using UltraHonk (required for Garaga)
bb prove_ultra_keccak_honk \
    -b ./target/donation_badge.json \
    -w ./target/witness.gz \
    -o ./target/proof.bin

# Generate verification key
bb write_vk_ultra_keccak_honk \
    -b ./target/donation_badge.json \
    -o ./target/vk.bin

# Verify proof locally (sanity check)
bb verify_ultra_keccak_honk \
    -k ./target/vk.bin \
    -p ./target/proof.bin

# Expected: Proof verified successfully

> Regenerate calldata via Garaga (optional):
> 
> ```bash
> garaga calldata \
>   --system ultra_keccak_honk \
>   --vk zk-badges/donation_badge/target/vk.bin \
>   --proof zk-badges/donation_badge/target/proof.bin \
>   --format array > calldata.txt
> ```
> This writes `calldata.txt` (ignored by git) at repo root and can be reproduced anytime.
```

---

## Step 4: Install Starknet Foundry (for contract deployment)

```bash
# Install snfoundryup
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh

# Reload shell
source ~/.bashrc

# Install Starknet Foundry
snfoundryup

# Verify
snforge --version
sncast --version
```

---

## Step 5: Generate Cairo Verifier Contract

```bash
# Activate Python environment
source ../garaga-env/bin/activate

# Generate Cairo verifier contract
cd ../..
garaga gen \
    --system ultra_keccak_honk_starknet \
    --vk zk-badges/donation_badge/target/vk.bin \
    --project-name donation_badge_verifier

# This creates a new Scarb project in ./donation_badge_verifier/

> Note: You can also generate calldata through the API as a reproducible alternative:
> 
> ```bash
> bun run api &
> curl -s -H 'Content-Type: application/json' \
>   -d '{"donationamount":"15000","threshold":"10000","donorsecret":"12345","badgetier":"2"}' \
>   http://localhost:3001/api/generate-proof
> ```
> The endpoint orchestrates witness → proof → vk → calldata and returns the `calldata` and `commitment`.
```

---

## Step 6: Integrate Badge Contract

After Garaga generates the verifier:

1. Copy `donation_badge_verifier/src/badge_contract.cairo` to the generated project
2. Update `donation_badge_verifier/src/lib.cairo` to import the verifier
3. Update `badge_contract.cairo` to use the generated verifier

```bash
cd donation_badge_verifier

# Build with Scarb
scarb build

# Output: Compiled donation_badge_verifier.contract_class.json
```

---

## Step 7: Deploy to Starknet

### Configure Deployment Account

Create `snfoundry.toml`:

```toml
[profile.sepolia]
account = "deployer"
accounts-file = "./accounts.json"
url = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/YOUR_ALCHEMY_KEY"
```

### Deploy Contract

```bash
# Declare the contract class
sncast --profile sepolia declare \
    --contract-name DonationBadge

# Note the class_hash from output
# Deploy instance
sncast --profile sepolia deploy \
    --class-hash <CLASS_HASH_FROM_ABOVE>

# Note the contract address
```

---

## Step 8: Update Badge Service

Update `src/badge-service.ts` with the deployed contract address:

```typescript
const BADGE_CONTRACT_ADDRESS = {
  mainnet: '0x...', // Update after mainnet deployment
  sepolia: '0x...'  // Update after testnet deployment
};
```

---

## Step 9: Install Browser Dependencies (Optional)

For browser-based proof generation, install:

```bash
npm install @noir-lang/noir_js @aztec/bb.js circomlibjs
```

Then copy the compiled circuit to `public/circuits/`:

```bash
cp zk-badges/donation_badge/target/donation_badge.json public/circuits/
```

---

## Testing End-to-End

1. Start the app: `bun run dev:web`
2. Connect your wallet
3. Navigate to the "Donation Badges" section
4. Enter donation amount and secret
5. Generate proof (may take 30-60 seconds)
6. Claim badge on-chain

---

## Troubleshooting (Preventive Steps)

- Inputs must meet tier thresholds to prevent Noir assertion failures:
    - Bronze: `donationamount ≥ 1000`
    - Silver: `donationamount ≥ 10000`
    - Gold: `donationamount ≥ 100000`
    - Ensure `badgetier` matches the intended threshold, and `threshold` aligns with the circuit’s checks.

- Ensure tools are on the pinned versions shown at the top. Re-run installers if mismatched:
    ```bash
    make install-all
    ```

- Garaga binary resolution:
    - Prefer PATH install: `~/.local/bin/garaga` (added by `pip --user`).
    - If using a venv, activate before running commands:
        ```bash
        source garaga-env/bin/activate
        ```

- Repo-relative paths only:
    - Run commands from the repository root unless stated otherwise.
    - Avoid absolute paths that reference external workspaces.

- If API returns 500 due to circuit assertions, validate the payload:
    ```bash
    curl -s -H 'Content-Type: application/json' \
        -d '{"donationamount":"15000","threshold":"10000","donorsecret":"12345","badgetier":"2"}' \
        http://localhost:3001/api/generate-proof
    ```
    This Silver-tier example should succeed.

