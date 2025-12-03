import { $ } from "bun";
import { writeFileSync, existsSync } from "fs";
import path from "path";
import { buildPoseidon } from "circomlibjs";

let poseidon: any = null;

async function getPoseidon() {
  if (!poseidon) {
    poseidon = await buildPoseidon();
  }
  return poseidon;
}

const server = Bun.serve({
  port: 3001,
  async fetch(req) {
    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Content-Type": "application/json",
    };

    if (req.method === "OPTIONS") {
      return new Response(null, { headers });
    }

    if (req.method === "POST" && req.url.includes("/api/generate-proof")) {
      try {
        const body = await req.json();
        const { donationamount, threshold, donorsecret, badgetier } = body;
        console.log("Generating proof for:", { donationamount, threshold, badgetier });

        const p = await getPoseidon();
        const hash = p([BigInt(donorsecret), BigInt(donationamount)]);
        const commitment = p.F.toString(hash);
        console.log("Computed commitment:", commitment);

        const proverToml = `donation_amount = ${donationamount}
donor_secret = ${donorsecret}
threshold = ${threshold}
badge_tier = ${badgetier}
donation_commitment = "${commitment}"
`;
        const repoRoot = process.cwd();
        const dir = path.join(repoRoot, "zk-badges", "donation_badge");
        const garagaEnvBin = path.join(repoRoot, "garaga-env", "bin", "garaga");
        const garagaBin = existsSync(garagaEnvBin) ? garagaEnvBin : "garaga";

        writeFileSync(path.join(dir, "Prover.toml"), proverToml);
        console.log("Running nargo execute...");
        await $`cd ${dir} && nargo execute witness`.quiet();
        console.log("Running bb prove...");
        await $`cd ${dir} && bb prove_ultra_keccak_honk -b ./target/donation_badge.json -w ./target/witness.gz -o ./target/proof`.quiet();
        console.log("Running bb write_vk...");
        await $`cd ${dir} && bb write_vk_ultra_keccak_honk -b ./target/donation_badge.json -o ./target/vk`.quiet();
        console.log("Running garaga calldata...");
        const result = await $`cd ${dir} && ${garagaBin} calldata --system ultra_keccak_honk --vk ./target/vk --proof ./target/proof --format array`.text();

        console.log("Proof generated successfully!");
        return new Response(JSON.stringify({ calldata: result.trim(), commitment, success: true }), { headers });
      } catch (error: any) {
        console.error("Error:", error.message || error);
        return new Response(JSON.stringify({ error: error.message || String(error), success: false }), { headers, status: 500 });
      }
    }
    return new Response(JSON.stringify({ error: "Not found" }), { headers, status: 404 });
  },
});

console.log("Proof API running on http://localhost:" + server.port);
