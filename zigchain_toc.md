# 📚 ZigChain Documentation – FAQ

This document contains categorized frequently asked questions for the ZigChain ecosystem.

---

## 📘 General

### Q: Do you already have an agreement with oracles?
**A:**  
We’re currently integrating with [Skip Protocol](https://www.skip.build/), one of the leading oracle solutions on Cosmos. More details will be shared as the integration progresses.

---

## 💰 ZIG Token
*(No entries yet)*

---

## 👤 Accounts
*(No entries yet)*

---

## ⛽ Gas Fees
*(No entries yet)*

---

## 📥 Staking

### Q: Can I delegate ZIG tokens from another wallet to my validator? Or do I need to run a second validator node?
**A:**  
You don’t need to run another validator node to delegate tokens from a different wallet. Any wallet can delegate ZIG tokens to any validator — including your own validator — using the validator’s address.

If you're using testnet and received tokens from the faucet, that wallet can delegate its balance to your validator. This is often referred to as self-delegation when the operator wallet does it, but delegation from other wallets works exactly the same way.

Here’s how to delegate tokens from any wallet:

```bash
zigchaind tx staking delegate <VALIDATOR_ADDRESS> <AMOUNT> \
  --from <DELEGATOR_ACCOUNT> \
  --chain-id zig-test-1 \
  --gas-adjustment 1.5 \
  --gas auto \
  --gas-prices="0.00025uzig"
```

📌 Replace:
- `<VALIDATOR_ADDRESS>` with your validator’s address (e.g., `zigvaloper...`)
- `<AMOUNT>` with the amount to delegate (e.g., `1000000uzig`)
- `<DELEGATOR_ACCOUNT>` with the name or address of the wallet you're using

👉 Refer to the official CLI command guide for more details: [ZigChain Staking CLI Quick Sheet](https://docs.zigchain.com/build/staking-module#staking-cli-quick-sheet)

---

### Q: Will it be possible to connect a Uniswap or other wallet to claim staking rewards?
**A:**  
You’ll need a Cosmos-compatible wallet to claim staking rewards. Since ZigChain is built on Cosmos SDK, staking and rewards will follow the same standard.

---

## 🗳️ Governance
*(No entries yet)*

---

## ⚙️ Consensus
*(No entries yet)*

---

## 🎁 Distribution
*(No entries yet)*

---

## 🧬 Mint
*(No entries yet)*

---

## ⚔️ Slashing
*(No entries yet)*

---

## 🌐 Endpoints

### Q: Is there a faucet available to get test ZIG tokens for development?
**A:**  
Yes! You can request free testnet ZIG tokens from the official ZigChain faucet:  
👉 Faucet URL: https://faucet.zigchain.com  
You can request tokens up to 2 times per day per wallet address from the same IP address.

---

### Q: Do you have a list of live peers currently active on the ZigChain testnet?
**A:**  
Yes — you can find the current list of seed nodes for the ZigChain testnet here:  
👉 [ZigChain Testnet Seed Nodes](https://github.com/ZIGChain/networks/blob/main/zig-test-1/seed-nodes.txt)  
These nodes can be used in your `config.toml` file under the `persistent_peers` or `seeds` field.

---

### Q: Where can I see my transaction details? Is there an explorer available?
**A:**  
Yes, you can view your transactions and blocks on the testnet explorer:  
👉 https://explorer.nodestake.org/zigchain-testnet

---

### Q: Can you point me to the SDK functions I can use?
**A:**  
You can use our API documentation for SDK-level interactions:  
👉 https://testnet-api.zigchain.com/#/

---

### Q: How can I see the latest blockchain height?
**A:**  
Run this command:
```bash
curl -s https://rpc.zigchain.com/status | jq '.result.sync_info.latest_block_height'
```

---

### Q: How can I check the status of a blockchain node?
**A:**  
Use this command:
```bash
curl -s https://rpc.zigchain.com/status
```

---

## 🧰 SDK

### Q: What hashing method should I use for uriHash? Is SHA-1 acceptable?
**A:**  
No — ZigChain uses **SHA-256** for `uriHash`.

SHA-256 is a cryptographic hash function that:
- Accepts any input (e.g., a URI or file),
- Produces a fixed-size 256-bit (32-byte) hash,
- Returns a unique and tamper-evident fingerprint of the original data.

🔐 **Why not SHA-1?**  
SHA-1 is considered outdated and vulnerable to collision attacks. ZigChain requires SHA-256 for stronger security.

👉 Refer to: [ZigChain Factory Creation Fields](https://docs.zigchain.com/build/factory#creation-fields)

---

## 🧪 ZigchainJS SDK
*(No entries yet)*

---

## 🖥️ Zigchain CLI

### Q: After installing zigchaind, any command I run gives this error: `error while loading shared libraries: /lib/libwasmvm.x86_64.so: file too short`. What’s causing this?
**A:**  
This usually means the required shared library is missing or incomplete, likely due to an interrupted download or build process.

**To fix it:**
```bash
sudo rm /lib/libwasmvm.x86_64.so
```

Then reinstall ZigChain from scratch, ensuring all downloads complete successfully.

---

### Q: What is the Chain ID for ZigChain’s testnet and local network?
**A:**  
Use the following Chain IDs:

- **Testnet:** `zig-test-1`  
- **Local development:** `zigchain-1`

Use `--chain-id zig-test-1` or `zigchain-1` accordingly when running commands.

---

## 🛰️ Nodes

### Q: Is there a way to quickly catch up a ZigChain node without using snapshots?
**A:**  
Right now, ZigChain nodes must sync from the genesis block. While we’ve tested faster methods internally, they’re not yet publicly available.

We’re working on providing an official solution (such as downloadable snapshots) soon.

---

### Q: Will State Sync be enabled for the ZigChain testnet or mainnet? Or should I sync from genesis?
**A:**  
We plan to support State Sync for both testnet and mainnet, but it is not yet enabled.

Please continue syncing from genesis using the published genesis file. We'll update the documentation once State Sync is available.

---

## 🛡️ Validators

### Q: My validator’s moniker status is showing as “Unbonded.” What are the requirements for it to become active?
**A:**  
A validator becomes active once it joins the **active set**, which is determined by the total amount of ZIG tokens staked.

There is no fixed minimum — only the top X validators (by stake) are included. For example, if only the top 3 are allowed, your validator must rank within those top 3 to be active.
