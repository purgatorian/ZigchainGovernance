# ZIGChain Governance

## Table of Contents

- [How to create a proposal](#how-to-create-a-proposal-on-zigchain-governance)
- [Deposit and Deposit Period](#-deposit-and-deposit-period)
- [Voting and Voting Period](#️-voting-and-voting-period)
- [Cancel a Proposal](#cancel-a-proposal)
- [Expedited Proposals](#expedited-proposals)
- [Governance Parameters](#params-of-the-governance-in-zigchain)
- [Proposal Types](#proposal-types)
- [References](#references)

ZIGChain governance is a decentralized decision-making process that allows ZIGChain users to participate in the network's future. Users can vote on proposals on a 1 ZIG 1 vote basis to change parameters, such as fees, number of validators, and other network parameters, or decide how to spent the ZIGChain funds. The governance process is essential for the decentralized nature of ZIGChain and ensures that the network evolves according to the community's consensus.

"If you're just looking for the quick commands..."

- 📘 [Governance Quick Sheet](https://docs.zigchain.com/build/governance-module#governance-cli-quick-sheet)
- 🖥️ See the commands in action with [governance.sh](./governance.sh)

## How to create a proposal on ZIGChain Governance?

Any ZIGChain user can create a proposal on ZIGChain governance by following these steps

### Step 1: Draft a Proposal

Use the following command to draft a governance proposal. It will prompt and guide you to enter the proposal details such as title, description, and deposit amount among others.

```sh
zigchaind tx gov draft-proposal
```

The command will prompt you to select the proposal type from the following options:

```sh
➜ zigchaind tx gov draft-proposal
Use the arrow keys to navigate: ↓ ↑ → ←
? Select proposal type:
  ▸ text
    community-pool-spend
    software-upgrade
    cancel-software-upgrade
    other
```

If you want to make a proposal for an item that it is not on the list, you can select the "other" option and it will show the list of proposal messages types available on ZIGChain. You can select the one that fits your proposal:

```sh
➜ zigchaind tx gov draft-proposal
✔ other
Use the arrow keys to navigate: ↓ ↑ → ←
? Select proposal message type::
  ▸ /cosmos.auth.v1beta1.MsgUpdateParams
    /cosmos.authz.v1beta1.MsgExec
    /cosmos.authz.v1beta1.MsgGrant
    /cosmos.authz.v1beta1.MsgRevoke
🔻   /cosmos.bank.v1beta1.MsgMultiSend
```

Follow the rest of the prompts to enter the proposal details such as title, description, deposit amount, and other relevant information.

Once process is completed, it will create two json files:

- draft_metadata.json - contains the proposal metadata
- draft_proposal.json - contains the proposal content

Take into account the following when creating your proposal:

1. The proposal deposit amount should be greater than the `minimum deposit amount * min_deposit_ratio` or `minimum deposit amount * min_initial_deposit_ratio` to be considered valid.
2. The metadata data needs to be replaced on the draft_proposal.json file. There are multiple options that you can use:
   - base64 encoded of the draft_metadata.json file
   - raw text
   - stringified json
   - IPFS link to json

Usually IPFS is the most suitable option due to the size of the metadata limitation. You can use [Pinata](https://pinata.cloud), [Web3 Storage](https://web3.storage), or any other IPFS service to upload the metadata file.

#### Uploading metadata to IPFS using Pinata (Linux)

##### 1. Get your Pinata API credentials

1. Go to [https://app.pinata.cloud/developer](https://app.pinata.cloud/developer).
2. If you don't have an account, sign up for one (it's free).
3. Once signed in, navigate to the **API Keys** section.
4. Click **New Key**, give it a name (e.g., `ZIGChain Upload Key`), and make sure to select **Admin access** or permissions for pinning files.
5. Copy the **JWT** (JSON Web Token) provided. This is what you will use to authenticate API requests.

You’ll use this JWT in the next step, either directly or by storing it in a variable for convenience.

##### (Optional) Store your JWT in a variable

To avoid repeating the token, you can store it in a shell variable:

```sh
export PINATA_JWT="<YOUR_JWT>"
```

##### 2. Automatically upload and update `draft_proposal.json` with the returned IPFS hash

```sh
curl -s -X POST https://api.pinata.cloud/pinning/pinFileToIPFS \
  -H "Authorization: Bearer $PINATA_JWT" \
  -F "file=@draft_metadata.json" | jq -r '.IpfsHash' | \
  xargs -I{} jq --arg cid "ipfs://{}" '.metadata = $cid' draft_proposal.json > updated_proposal.json && mv updated_proposal.json draft_proposal.json
```

3. Some proposals may require an Authority in the information provided. This field should match with the Governance Account that it is under Auth Module. To get the Governance Account, you can use the following command:

```sh
zigchaind query auth accounts
```

and look for the address in the list under `type: cosmos-sdk/ModuleAccount` with `name: gov`.

### Step 2: Submit a Proposal

Once you have drafted the proposal, you can submit it using the following command:

```sh
zigchaind tx gov submit-proposal draft_proposal.json --from <key-name> --chain-id ZIGChain --node <node-url> --gas-prices 0.25uzig --gas auto --gas-adjustment 1.3
```

Example:

```sh
zigchaind tx gov submit-proposal draft_proposal.json --from valuser1 --chain-id zigchain-1 --node http://localhost:26657 --gas-prices 0.25uzig --gas auto --gas-adjustment 1.3
```

The response would provide you the transaction id in the blockchain like this:

```sh
{
  "code": 0,
  "codespace": "",
  "data": "",
  "events": [],
  "gas_used": "0",
  "gas_wanted": "0",
  "height": "0",
  "info": "",
  "logs": [],
  "raw_log": "",
  "timestamp": "",
  "tx": null,
  "txhash": "6310A6829867FD6722922ADA208AF5F4BEB9478917B699B879FC2EF96C8FCC3E"
}

```

If during submitting the proposal you get an error like this:

```sh
expected gov account as only signer for proposal message
```

It means that in the proposal the authority field doesn't match with the account that it is submitting the proposal. You need to update the authority field in the proposal to match the account that is submitting the proposal.

### Step 3: Confirm your proposal has been created:

To confirm that your proposal has been created, you can get the proposal id from the transaction id obtained during step 2 and query the proposal using the following command:

```sh
$PROPOSAL_ID=1
zigchaind query gov proposal $PROPOSAL_ID
```

Example Response:

```plaintext
deposit_end_time: "2024-10-16T10:02:52.465397Z"
final_tally_result:
 abstain_count: "0"
 no_count: "0"
 no_with_veto_count: "0"
 yes_count: "1000000000"
id: "1"
messages:
- type: cosmos-sdk/x/staking/MsgUpdateParams
 value:
   authority: zig10d07y265gmmuvt4z0w9aw880jnsr700jmgkh5m
   params:
     bond_denom: uzig
     historical_entries: 10000
     max_entries: 7
     max_validators: 100
     min_commission_rate: "50000000000000000"
     unbonding_time: 336h0m0s
metadata: ipfs://Qmajr22xYgoi3VGgnoUWDMYWittB4vp1udcfjuirEFxBkW
proposer: zig15xwallkarj7jmwkezfs6kf9z4q6tdy7ys08f9p
status: PROPOSAL_STATUS_PASSED
submit_time: "2024-10-14T10:02:52.465397Z"
summary: Proposal to increase from 50 to 100 validators the active set
title: Proposal to increase to 100 validators the active set
total_deposit:
- amount: "5000000000000"
 denom: uzig
voting_end_time: "2024-10-14T10:04:34.526219Z"
voting_start_time: "2024-10-14T10:02:54.526219Z"
```

Response Fields Explanation:

- `deposit_end_time`: The time when the deposit period ends.
- `final_tally_result`: The final tally result of the proposal. Updated once the voting period ends.
- `id`: The proposal id. Use this id to query the proposal.
- `messages`: The messages included in the proposal. It will be executed if the proposal passes.
- `metadata`: The metadata of the proposal. It can be a base64 encoded, raw text, stringified json, or IPFS link to json.
- `proposer`: The address of the proposer.
- `status`: The status of the proposal. Check below details about the possible options.
- `submit_time`: The time when the proposal was submitted.
- `summary`: A short summary of the proposal.
- `title`: The title of the proposal.
- `total_deposit`: The total deposit amount of the proposal.
- `voting_end_time`: The time when the voting period ends.
- `voting_start_time`: The time when the voting period starts.

The following are the possible proposal statuses:

- PROPOSAL_STATUS_UNSPECIFIED: The default proposal status.
- PROPOSAL_STATUS_DEPOSIT_PERIOD: The proposal status during the deposit period.
- PROPOSAL_STATUS_VOTING_PERIOD: The proposal status during the voting period.
- PROPOSAL_STATUS_PASSED: The proposal status of a proposal that has passed.
- PROPOSAL_STATUS_REJECTED: The proposal status of a proposal that has been rejected.
- PROPOSAL_STATUS_FAILED: The proposal status of a proposal that has failed.

If not, you can check the proposals list using the following command:

```sh
zigchaind query gov proposals
```

## 🧹 Deposit and Deposit Period

Once a proposal is created, it enters the **deposit period**, during which it must receive at least the `minimum deposit amount` to proceed to the voting stage.

- If the total deposit remains **below the threshold**, the proposal is **closed** at the end of the deposit period and the deposit is **returned to the proposer**.
- If the deposit exceeds the threshold **within the period**, the proposal enters the **voting period**.

To check the current status of the proposal (including deposit timings), use:

```sh
zigchaind query gov proposal $PROPOSAL_ID
```

### 💸 Deposit on a Proposal

```sh
zigchaind tx gov deposit $PROPOSAL_ID <amount> --from <key-name> --chain-id <chain-id> --fees 50uzig --gas auto --gas-adjustment 1.2
```

#### Example:

```sh
zigchaind tx gov deposit $PROPOSAL_ID 1000000uzig --from zuser1 --chain-id zigchain-1 --fees 50uzig --gas auto --gas-adjustment 1.2
```

Once the deposit exceeds the threshold, the proposal automatically moves into the **voting phase**.

---

## 🗳️ Voting and Voting Period

Only users with **bonded (staked) ZIG tokens** can vote. The **voting power** is proportional to the amount of ZIGs bonded.

🧠 **Important Notes:**

- Only **bonded ZIGs** count.
- If you do not vote, your vote will follow that of the validator you are delegated to.

### ✅ Voting Options

- `Yes`
- `No`
- `No with Veto`
- `Abstain`

### 🗳️ Vote Command

```sh
zigchaind tx gov vote <proposal-id> <option> --from <key-name> --chain-id <chain-id> --fees 50uzig
```

#### Example:

```sh
zigchaind tx gov vote $PROPOSAL_ID yes --from zuser1 --chain-id zigchain-1 --fees 50uzig
```

### ⚖️ Weighted Voting

You can also cast a weighted vote:

```sh
zigchaind tx gov weighted-vote <proposal-id> yes=0.6,no=0.3,abstain=0.05,no_with_veto=0.05 --from <key-name>
```

---

### 📊 Check Vote Status

- **View overall tally:**

```sh
zigchaind query gov tally <proposal-id>
```

- **View your individual vote:**

```sh
zigchaind query gov vote <proposal-id> <voter-addr>
```

---

### 🤨 Not Seeing Your Vote?

You may not be staking with your current address. To check:

```sh
zigchaind query staking delegations $(zigchaind keys show <account-name> --address) --chain-id zigchain-1
```

#### Example:

```sh
zigchaind query staking delegations $(zigchaind keys show zuser3 --address) --chain-id zigchain-1
```

**Empty response?** You’re not delegated yet. Follow the next steps to stake:

---

### 🔐 Delegate to a Validator

1. **Find a validator:**

```sh
zigchaind query staking validators --chain-id zigchain-1 --output json | jq -r '.validators[] | "\(.description.moniker): \(.operator_address)"'
```

2. **Delegate your tokens:**

```sh
zigchaind tx staking delegate <validator-address> <amount> \
  --from <account-name> \
  --chain-id zigchain-1 \
  --fees 50uzig \
  --gas auto \
  --gas-adjustment 1.2
```

#### Example:

```sh
zigchaind tx staking delegate zigvaloper10ckuk5ltxzld45yy66fmz8gcc6qjvsty39zlvl 100000000000000000000uzig \
  --from zuser3 \
  --chain-id zigchain-1 \
  --fees 50uzig \
  --gas auto \
  --gas-adjustment 1.2
```

3. **Verify delegation:**

```sh
zigchaind query staking delegations $(zigchaind keys show zuser3 --address) --chain-id zigchain-1
```

Expected response:

```yaml
delegation_responses:
  - balance:
      amount: "100000000000000000000"
      denom: uzig
    delegation:
      delegator_address: zig1fh0pqu3kdn4cu3waqmd3pfj66tgsnqrs9ls8vf
      shares: "100000000000000000000.000000000000000000"
      validator_address: zigvaloper10ckuk5ltxzld45yy66fmz8gcc6qjvsty39zlvl
```

Now you can vote using this new wallet address.

## Voting Results

Once the voting period ends, the proposal is closed, and the final tally result is calculated.

First of all, it is necessary that the proposal reaches the quorum. The quorum is the minimum percentage of the total voting power that needs to vote for the proposal to be valid. If the proposal doesn't reach the quorum, the proposal is closed, and the deposit is returned to the proposer.

If the proposal reaches the quorum, depending on the votes we can have the following circumstances:

- Veto is reached: If the No with Veto votes are greater than the Veto Threshold (including Abstain Votes), the proposal is rejected.
- YES votes are greater than the Threshold (excluding Abstain Votes), the proposal is passed (`PROPOSAL_STATUS_PASSED`).
- If the YES votes are less than the Threshold, the proposal is rejected (`PROPOSAL_STATUS_REJECTED`).

Once the proposal is passed, if during the execution of the proposal an error occurs, the proposal is marked as failed (`PROPOSAL_STATUS_FAILED`).

If the proposal is passed or rejected, the deposit is returned to the proposer and those who deposited on the proposal. If the proposal was vetoed, the deposit coins are burned.

## Cancel a Proposal

It is possible to cancel a proposal if the proposer decides to do so. To cancel a proposal, use the following command:

```sh
zigchaind tx gov cancel-proposal <proposal-id> --from <key-name> --chain-id <chain-id> --node <node-url> --fees <fees> --gas <gas>
```

## Expedited Proposals

Expedited proposals are proposals that have a shorter deposit and voting period. The expedited proposals are used for urgent matters that need to be resolved quickly. The expedited proposals have a shorter voting period, and the threshold is higher than the regular proposals (requires more Yes votes).

To create an expedited proposal, you need to set the `expedited` field to `true` in the proposal data.

## 🧾 Query Proposal Votes

**Template:**

```sh
zigchaind query gov votes <proposal-id>
```

Example:

```sh
zigchaind query gov votes 1
```

## 🧾 Query Proposal Deposits

**Template:**

```sh
zigchaind query gov deposits <proposal-id>
```

Example:

```sh
zigchaind query gov deposits 1
```

Shows all deposit transactions for proposal ID 1.

## Params of the Governance in ZIGChain

You can query the governance parameters using the following command:

```sh
zigchaind query gov params
```

The current params are:

```json
{
  "burn_vote_veto": true,
  "burn_proposal_deposit": false,
  "burn_vote_quorum": false,
  "expedited_min_deposit": [
    {
      "amount": "100000000000000",
      "denom": "uzig"
    }
  ],
  "expedited_threshold": "0.667000000000000000",
  "expedited_voting_period": "24h0m0s",
  "max_deposit_period": "48h0m0s",
  "min_deposit": [
    {
      "amount": "5000000000000",
      "denom": "uzig"
    }
  ],
  "min_deposit_ratio": "0.010000000000000000",
  "min_initial_deposit_ratio": "0.000000000000000000",
  "proposal_cancel_ratio": "0.500000000000000000",
  "quorum": "0.334000000000000000",
  "threshold": "0.500000000000000000",
  "veto_threshold": "0.334000000000000000",
  "voting_period": "48h0m0s"
}
```

## Proposal Types

There are different types of proposals that can be created on ZIGChain governance. The proposal types are:

- Text: A text proposal that can be used for any type of proposal.
- Community Pool Spend: A proposal to spend funds from the community pool. The community pool is a pool of funds that can be used for network development, marketing, and other purposes.
- Software Upgrade: A proposal to upgrade the software.
- Cancel Software Upgrade: A proposal to cancel a software upgrade.
- Other: A proposal for other types of proposals. This option will show the list of proposal messages types available on ZIGChain. You can select the one that fits your proposal. Any possible message supported by the ZIGChain and whitelisted can be used. ❌ Confirm

## References:

- **ZIGChain - Governance's Quick Sheet:**

[Governance Quick Sheet][Governance Quick Sheet]

- **ZIGChain - Governance's Shell Script:**

[governance.sh][governance.sh]

- **Cosmos SDK - Governance Module:**

https://docs.cosmos.network/main/build/modules/gov

<!--- ZIGChain - References -->

[Governance Quick Sheet]: https://docs.zigchain.com/build/governance-module#governance-cli-quick-sheet
[governance.sh]: ./governance.sh
