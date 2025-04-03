# 🧪 Governance.sh Run Tests

## Original File:

[governance.sh](governance.sh)

## Updated File:

[governance_updated.sh](governance_updated.sh)

---

<aside>
### 🔐 Prevent Wallet Passphrase Prompts

Script prompts account password with each refresh. If you ever get tired of it follow the steps below.

Add this text to top of the script

```jsx
PASSPHRASE="12345678"

```

locate account lines: 

```bash
ACCOUNT_Z=valuser1
pv "ACCOUNT_Z" ACCOUNT_Z

ACCOUNT_ADDRESS_Z=$(zigchaind keys show $ACCOUNT_Z -a)
pv "$ACCOUNT_Z account address" ACCOUNT_ADDRESS_Z

ACCOUNT_1=zuser1
pv "ACCOUNT_1" ACCOUNT_1

ACCOUNT_ADDRESS_1=$(zigchaind keys show $ACCOUNT_1 -a)
pv "$ACCOUNT_1 account address" ACCOUNT_ADDRESS_1

ACCOUNT_2=zuser2
pv "ACCOUNT_2" ACCOUNT_2

ACCOUNT_ADDRESS_2=$(zigchaind keys show $ACCOUNT_2 -a)
pv "$ACCOUNT_2 account address" ACCOUNT_ADDRESS_2

ACCOUNT_3=zuser3
pv "ACCOUNT_3" ACCOUNT_3

ACCOUNT_ADDRESS_3=$(zigchaind keys show $ACCOUNT_3 -a)
pv "$ACCOUNT_3 account address" ACCOUNT_ADDRESS_3
```

to this:

```bash
ACCOUNT_Z=valuser1
pv "ACCOUNT_Z" ACCOUNT_Z

ACCOUNT_ADDRESS_Z=$(echo "$PASSPHRASE" | zigchaind keys show $ACCOUNT_Z -a)
pv "$ACCOUNT_Z account address" ACCOUNT_ADDRESS_Z

ACCOUNT_1=zuser1
pv "ACCOUNT_1" ACCOUNT_1

ACCOUNT_ADDRESS_1=$(echo "$PASSPHRASE" | zigchaind keys show $ACCOUNT_1 -a)
pv "$ACCOUNT_1 account address" ACCOUNT_ADDRESS_1

ACCOUNT_2=zuser2
pv "ACCOUNT_2" ACCOUNT_2

ACCOUNT_ADDRESS_2=$(echo "$PASSPHRASE" | zigchaind keys show $ACCOUNT_2 -a)
pv "$ACCOUNT_2 account address" ACCOUNT_ADDRESS_2

ACCOUNT_3=zuser3
pv "ACCOUNT_3" ACCOUNT_3

ACCOUNT_ADDRESS_3=$(echo "$PASSPHRASE" | zigchaind keys show $ACCOUNT_3 -a)
pv "$ACCOUNT_3 account address" ACCOUNT_ADDRESS_3
```

</aside>

## ✅ 1. `cb:6: command not found: bat`

**📌 Reason:**

`bat` is not installed. On Ubuntu, it may be installed as `batcat`.

**🛠️ Solution:**

### ➤ Option 1: Check for `batcat` and symlink it

```bash
which batcat

```

If output is:

```bash
/usr/bin/batcat

```

Then run:

```bash
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

```

### ➤ Option 2: Install `bat` directly

```bash
sudo apt update
sudo apt install bat

```

---

## ✅ 2. `z is not a valid name or address`

**🔍 Script output:**

```bash
# - - - - - - - - - - - - - - - - - - - -
ACCOUNT_Z
ACCOUNT_Z=z
# - - - - - - - - - - - - - - - - - - - -
z is not a valid name or address: decoding bech32 failed: invalid bech32 string length 1

```

**📌 Reason:**

The value `z` assigned to `ACCOUNT_Z` is invalid. No key named `z` exists in the keyring.

**🛠️ Solution:**

- Option 1: Create a new wallet called `z`
- ✅ Option 2 (Recommended): Change `z` to an existing account like `valuser1`

### 🔧 Fix:

Change:

```bash
ACCOUNT_Z=z

```

To:

```bash
ACCOUNT_Z=valuser1

```

---

## ✅ 3. `tx not found` Error

**🔍 Command:**

```bash
  zigchaind query tx --type=[hash|acc_seq|signature] [hash|acc_seq|signature] [flags]
```

**❌ Error:**

```
error in json rpc client, with http response metadata: (Status: 200 OK, Protocol HTTP/1.1). RPC error -32603 - Internal error: tx (218D47F88BEC459F22695BEAE50CAA739AEE7D164E60DC53942F9833BD054654) not found
```

**📌 Reason:**

Chain ID mismatch — script uses `zigchain` but your node is running with `zigchain-1`.

Also, this part of the returned JSON confirms the issue:

Run this command to trigger proposal manually

```bash
zigchaind tx gov submit-proposal /tmp/draft_proposal.json \
  --from=zuser1 \
  --chain-id=zigchain \
  --node=http://localhost:26657 \
  --gas-prices 0.25uzig \
  --gas auto \
  --gas-adjustment 1.3 \
  -y --output json

```

Outcome:

```bash
gas estimate: 213768
{"height":"0",
"txhash":"218D47F88BEC459F22695BEAE50CAA739AEE7D164E60DC53942F9833BD054654",
"codespace":"sdk","code":4,"data":"",
"raw_log":"signature verification failed; please verify account number (1) and chain-id (zigchain-1): (unable to verify single signer signature): unauthorized","logs":[],"info":"","gas_wanted":"0","gas_used":"0","tx":null,"timestamp":"","events":[]}
```

**🛠️ Solution:**

Update your script to match your actual running chain ID.

### 🔧 Fix:

Change this line:

```bash
CHAIN_ID="zigchain"

```

To:

```bash
CHAIN_ID="zigchain-1"

```

Ensure this matches the output of:

```bash
zigchaind status | jq -r '.NodeInfo.network'

```

---

## ✅ 4. `unknown shorthand flag: '4' in -499999900uzig`

**🔍 Script Output:**

```
4️⃣: zuser2 deposits to make the proposal active
Usage:
  zigchaind tx gov deposit [proposal-id] [deposit] [flags]
unknown shorthand flag: '4' in -499999900uzig

```

**📌 Reason:**

A **negative deposit amount** was calculated, which is invalid. This typically happens when:

- The current deposit already meets or exceeds the minimum
- The calculation of `DEPOSIT_REQUIRED` results in a negative number

Example:

```bash
DEPOSIT_REQUIRED=$(($MIN_DEPOSIT - $CURRENT_DEPOSIT))

```

If `CURRENT_DEPOSIT` is greater than `MIN_DEPOSIT`, this will return a negative value.

Then this gets passed to:

```bash
zigchaind tx gov deposit $PROPOSAL_ID ${DEPOSIT_REQUIRED}uzig ...

```

...causing the CLI to interpret `-` as a flag.

---

**🛠️ Solution:**

Wrap the calculation in a **max guard** to prevent negative values.

### 🔧 Fix:

Update this part:

```bash
DEPOSIT_REQUIRED=$(($MIN_DEPOSIT - $CURRENT_DEPOSIT))

```

To this:

```bash
DEPOSIT_REQUIRED=$(( $MIN_DEPOSIT - $CURRENT_DEPOSIT ))
if [[ "$DEPOSIT_REQUIRED" -lt 0 ]]; then
  echo "✅ Proposal already has enough deposit. Skipping extra deposit." | cb
  DEPOSIT_REQUIRED=0
fi

```

And **skip the deposit transaction** if `DEPOSIT_REQUIRED` is zero:

```bash
if [[ "$DEPOSIT_REQUIRED" -gt 0 ]]; then
  DEPOSIT_PROPOSAL_ID=$(
    echo "$PASSPHRASE" | zigchaind tx gov deposit $PROPOSAL_ID "${DEPOSIT_REQUIRED}uzig" \\
      --from=$ACCOUNT_2 \\
      "${TX_FLAGS[@]}" -y --output json | tx_id
  )
  pv "DEPOSIT_PROPOSAL_ID" DEPOSIT_PROPOSAL_ID
else
  echo "⏭️  No deposit needed. Proposal already active." | cb
fi

```

---

This prevents the transaction from running with a negative amount and avoids the `unknown shorthand flag` error entirely.

---

## ✅ 5. `date: invalid option -- 'j'` on Linux

**🔍 Script Output:**

```
✨INFO: Confirming that the voting period has started
2025-03-25T21:30:33.947163717Z
date: invalid option -- 'j'
Try 'date --help' for more information.

```

**📌 Reason:**

The script is using `date -j -f ...`, which is **only supported on macOS**. On Linux (Ubuntu, WSL, etc.), this results in an error.

The problematic code:

```bash
# macOS only
START_TIME_CLEAN=$(echo "$START_TIME" | sed -E 's/\\.[0-9]+Z/Z/')
START_TIME_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$START_TIME_CLEAN" +"%s")

```

Linux doesn't support the `-j` or `-f` flags with the `date` command.

---

**🛠️ Solution:**

Use a **platform check** (`$OSTYPE`) to use the correct version of the `date` command based on the OS.

### 🔧 Fix:

Replace the existing date parsing block with this:

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  START_TIME_CLEAN=$(echo "$START_TIME" | sed -E 's/\\.[0-9]+Z/Z/')
  START_TIME_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$START_TIME_CLEAN" +"%s")
else
  # Linux
  START_TIME_EPOCH=$(date -d "$START_TIME" +"%s")
fi

```

✅ This ensures that both macOS and Linux users can run the script without modification.

---

## ✅ 6. `tx not found` when querying transaction

**🔍 Script Output:**

```
✨INFO: Ensuring no errors in transaction
Usage:
  zigchaind query tx --type=[hash|acc_seq|signature] [hash|acc_seq|signature] [flags]

error in json rpc client, with http response metadata: (Status: 200 OK, Protocol HTTP/1.1). RPC error -32603 - Internal error: tx (A5B5B34D0829E43DED993340BDD88889D3F4C73F1F09F782CCEF04F6CE1802E0) not found

```

**📌 Reason:**

You're querying a transaction hash before it's been indexed by the node. Even if it's been broadcast, the transaction might take a few seconds to be:

- Included in a block
- Indexed for queries via `zigchaind query tx`

---

**🛠️ Solution:**

Add a **retry loop** that waits for the transaction to appear on-chain before querying it.

### 🔧 Fix:

Replace this line:

```bash
TX_JSON=$(zigchaind q tx "$VOTE_ID" --output json)

```

With a retry-safe block:

```bash
TX_JSON=""
echo "⏳ Waiting for vote transaction to be indexed..." | cb

for i in {1..10}; do
  TX_JSON=$(echo "$PASSPHRASE" | zigchaind query tx "$VOTE_ID" --output json 2>/dev/null || true)
  if echo "$TX_JSON" | jq -e '.txhash' &>/dev/null; then
    echo "✅ Vote transaction found and included in block." | cb
    break
  else
    echo "⏳ Still waiting... ($i/10)" | cb
    sleep 2
  fi
done

if [[ -z "$TX_JSON" ]]; then
  echo "❌ Failed to find vote transaction after waiting." | cb
  exit 1
fi

# Continue processing the transaction
echo -n "Raw Log: "
echo "$TX_JSON" | jq '.raw_log'

```

This loop retries up to 10 times (waiting 2 seconds each time), giving your local node time to catch up and index the transaction.

---

## ✅ 8. Voting Behavior: One Vote Was Ineffective, One Was Effective

### 🧪 Context from the Script

The script initiates two votes:

- One from `ACCOUNT_3` (defined as `zuser3`)
- One from `ACCOUNT_Z` (defined as `valuser1`)

---

### 🗳️ First Vote – Ineffective

```
✨INFO: Getting the Proposal Votes Information and see that vote was not effective
{
  "tally": {
    "yes_count": "0",
    "abstain_count": "0",
    "no_count": "0",
    "no_with_veto_count": "0"
  }
}

```

> 🟡 Although the vote transaction from ACCOUNT_3 succeeded, it had no impact on the tally.
> 

---

### ✅ Second Vote – Effective

```
✨INFO: Getting the Proposal Votes Information and see that vote was effective
{
  "tally": {
    "yes_count": "100000000000000000",
    "abstain_count": "0",
    "no_count": "0",
    "no_with_veto_count": "0"
  }
}

```

> ✅ The vote from ACCOUNT_Z was counted and updated the tally with the full bonded voting power.
> 

---

### 🔍 Why This Happened

- `ACCOUNT_3` (`zuser3`) is **not a bonded (staked) account** — it has no voting power.
- `ACCOUNT_Z` (`valuser1`) **is a staked validator account** — its vote carries weight and is counted in the governance tally.

This follows ZIGChain governance rules (based on Cosmos SDK):

> ✅ Only bonded accounts (validators or stakers) can vote with weight.
> 
> 
> 🛑 Accounts with no staking do not affect the proposal outcome, even if their transaction succeeds.
> 

---

### 🧠 Notes

- A vote can be valid on-chain but still carry **zero weight**.
- Delegators who are not staked do **not** influence the tally.
- If a delegator does not vote, it **inherits the vote of its validator** (if bonded).

---

### 📌 Takeaway

| Account | Voted | Bonded? | Vote Effective? |
| --- | --- | --- | --- |
| `zuser3` | ✅ | ❌ No | ❌ No |
| `valuser1` | ✅ | ✅ Yes | ✅ Yes |

Always ensure your voting account is staked (has bonded ZIG tokens), or vote using a validator account.

---
