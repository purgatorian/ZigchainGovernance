#!/usr/bin/env zsh
# Runs common commands to test the contract on-fly during development
# not meant to replace unit or integration tests

MODULE_NAME="staking"
PASSPHRASE="12345678"
# stop a script if at any point anything fails (or a variable is missed)
set -o errexit -o nounset -o pipefail

# Function to handle exit
final_print() {
  local exit_code=$?
  if ((exit_code != 0)); then
    printf "Script failed with error code: %d\n" "$exit_code" >&2
    echo "To reload the environment variables, run:"
    echo "source /tmp/.$MODULE_NAME.mod.env" | cb bash
  fi
}

# Nice printing
cb () {
  local FORMATING THEME

  FORMATING=${1-yaml}
  THEME=${2-DarkNeon}

  bat -l "$FORMATING" - --theme="$THEME" --style plain --color always
}

tx_id() {
  local data
  if ! data=$(cat); then
    printf "Failed to read transaction id\n" >&2
    return 1
  fi

  # Process the input data with jq
  echo "${data}" | jq -r '.txhash'
}

CHAIN_ID="zigchain-1"
RPC="http://localhost:26657"
NODE=(--node "$RPC")
TX_FLAGS=("${NODE[@]}" --chain-id "$CHAIN_ID" --gas-prices 0.25uzig --gas auto --gas-adjustment 1.3)
TX_FLAGS_NO_GAS_ADJ=("${NODE[@]}" --chain-id "$CHAIN_ID" --gas-prices 0.25uzig --gas auto)

# run clean in case of exit
trap final_print EXIT

# shut up shellcheck complaining how it cannot follow local path
# shellcheck source=/dev/null
#. $HOME/src/zigchain/scripts/env.sh

echo "# ENV for $MODULE_NAME script" >/tmp/.$MODULE_NAME.mod.env

# print var name and value in a pretty way
# also save it to a file, so we can load it later
pv() {
  local title="$1"
  local var_name="$2"

  echo
  echo "# - - - - - - - - - - - - - - - - - - - -"

  echo "$title" | cb
  # Make it work for both bash and zsh
  eval "printf '%s=%s\\n' \"\$var_name\" \"\${$var_name}\"" | cb bash
  echo "# $title" >>/tmp/.$MODULE_NAME.mod.env
  eval "printf '%s=%s\\n' \"\$var_name\" \"\${$var_name}\" >> /tmp/.$MODULE_NAME.mod.env"

  echo "# - - - - - - - - - - - - - - - - - - - -"
  echo
}

# --------------------------------------------------------------------------------------------
# SETUP VARIABLES
# --------------------------------------------------------------------------------------------

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

# General flags used in commands
pv "TX_FLAGS" $TX_FLAGS

# --------------------------------------------------------------------------------------------
# MAKE A GOVERNANCE PROPOSAL
# --------------------------------------------------------------------------------------------

echo "\n 🚀 EXEC: $ACCOUNT_1 makes a Governance Proposal to increase the number of validators" | cb

echo "\n 1️⃣: Get the current staking params" | cb
STAKING_PARAMS=$(zigchaind query staking params --output json)

echo $STAKING_PARAMS

echo "\n 2️⃣: Metadata used for the Proposal" | cb
METADATA_JSON=$(
  echo -n '{
  "title": "Proposal to increase to 100 validators the active set",
  "authors": ['$ACCOUNT_1'],
  "summary": "Proposal to increase from 50 to 100 validators the active set",
  "details": "After the successful launch of the ZigChain Mainnet, the network has been stable and secure. We propose to increase the number of validators from 50 to 100 to further decentralize the network and increase its security.",
  "proposal_forum_url": "https://forum.zigchain.com",
  "vote_option_context": "This proposal is to increase to 100 validators the active set"
}'
)

echo $METADATA_JSON

echo "\ This metadata has been stored in IPFS" | cb

echo "\n 3️⃣: Getting the Governance Account" | cb
GOVERNANCE_ACCOUNT=$(zigchaind query auth accounts -o json | jq -r '.accounts[] | select(.value.name == "gov") | .value.address')

pv "GOVERNANCE_ACCOUNT" GOVERNANCE_ACCOUNT

echo "\n 4️⃣: Creating the Proposal JSON" | cb
PROPOSAL_JSON=$(cat <<EOF
{
 "messages": [
  {
   "@type": "/cosmos.staking.v1beta1.MsgUpdateParams",
   "authority": "$GOVERNANCE_ACCOUNT",
   "params": {
    "unbonding_time": "1209600s",
    "max_validators": 100,
    "max_entries": 7,
    "historical_entries": 10000,
    "bond_denom": "uzig",
    "min_commission_rate": "0.05"
   }
  }
 ],
 "metadata": "ipfs://Qmajr22xYgoi3VGgnoUWDMYWittB4vp1udcfjuirEFxBkW",
 "deposit": "500000000uzig",
 "title": "Proposal to increase to 100 validators the active set",
 "summary": "Proposal to increase from 50 to 100 validators the active set",
 "expedited": false
}
EOF
)

echo $PROPOSAL_JSON

bash -c "cat > /tmp/draft_proposal.json" <<EOM
$PROPOSAL_JSON
EOM

echo "\n 🚀 EXEC: Submitting the proposal" | cb
SUBMIT_PROPOSAL_ID=$(
  zigchaind tx gov submit-proposal /tmp/draft_proposal.json \
    --from=$ACCOUNT_1 \
    $TX_FLAGS -y --output json | tx_id
)

pv "SUBMIT_PROPOSAL_ID" SUBMIT_PROPOSAL_ID

echo "Waiting for: proposal to be included in a block" | cb
sleep 3

echo "\n ✨INFO: Getting the Proposal Id from the Submitted Message" | cb

PROPOSAL_ID=$(zigchaind query tx $SUBMIT_PROPOSAL_ID --output json | jq -r '.events[] | select(.attributes[] | select(.key == "proposal_id")).attributes[] | select(.key == "proposal_id").value' | head -n 1)

pv "PROPOSAL_ID" PROPOSAL_ID

echo "\n ✨INFO: Getting the Proposal Information" | cb

PROPOSALS_INFO=$(zigchaind q gov proposal $PROPOSAL_ID --output json)

echo $PROPOSALS_INFO

# --------------------------------------------------------------------------------------------
# ANOTHER ACCOUNT COMPLETES THE DEPOSIT TO MAKE THE PROPOSAL ACTIVE
# --------------------------------------------------------------------------------------------

echo "\n 🚀 EXEC: $ACCOUNT_2 deposits to make the proposal active" | cb

echo "\n 1️⃣: Getting the current Proposal Deposit Amount" | cb
CURRENT_DEPOSIT=$(zigchaind query gov proposal $PROPOSAL_ID --output json | jq -r '.proposal.total_deposit[] | select(.denom == "uzig") | .amount')

pv "CURRENT_DEPOSIT" CURRENT_DEPOSIT

echo "\n 2️⃣: Calculating how much is required for proposal to pass" | cb
MIN_DEPOSIT=$(zigchaind query gov params --output json | jq -r '.params.min_deposit[] | select(.denom == "uzig") | .amount')

pv "MIN_DEPOSIT" MIN_DEPOSIT

echo "\n 3️⃣: Calculating how much is required for proposal to pass" | cb
DEPOSIT_REQUIRED=$(( $MIN_DEPOSIT - $CURRENT_DEPOSIT ))
if [[ "$DEPOSIT_REQUIRED" -lt 0 ]]; then
  echo "✅ Proposal already has enough deposit. Skipping extra deposit." | cb
  DEPOSIT_REQUIRED=0
fi

pv "DEPOSIT_REQUIRED" DEPOSIT_REQUIRED

echo "\n 4️⃣: $ACCOUNT_2 deposits to make the proposal active" | cb
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


echo "Waiting for: deposit to be included in a block" | cb
sleep 1

echo "\n ✨INFO: Getting the Proposal Information" | cb

PROPOSALS_INFO=$(zigchaind q gov proposal $PROPOSAL_ID --output json)

echo $PROPOSALS_INFO

echo "\n ✨INFO: Confirming that the voting period has started" | cb
echo $PROPOSALS_INFO | jq -r '.proposal.voting_start_time'

START_TIME=$(echo $PROPOSALS_INFO | jq -r '.proposal.voting_start_time')

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  START_TIME_CLEAN=$(echo "$START_TIME" | sed -E 's/\\.[0-9]+Z/Z/')
  START_TIME_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$START_TIME_CLEAN" +"%s")
else
  # Linux
  START_TIME_EPOCH=$(date -d "$START_TIME" +"%s")
fi


pv "START_TIME" START_TIME
pv "CURRENT_TIME" $(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [[ $(date +%s) -lt "$START_TIME_EPOCH" ]]; then
  echo "Voting period has not started yet" | cb
else
  echo "Voting period has started" | cb
fi

# --------------------------------------------------------------------------------------------
# ACCOUNT 3 TRIES TO VOTE ON THE PROPOSAL
# --------------------------------------------------------------------------------------------

echo "\n 🚀 EXEC: $ACCOUNT_3 votes YES on the proposal" | cb

echo "Waiting for: vote to be ready" | cb
sleep 5

VOTE_ID=$(
  zigchaind tx gov vote $PROPOSAL_ID yes \
    --from=$ACCOUNT_3 \
    $TX_FLAGS_NO_GAS_ADJ --gas-adjustment 2 -y --output json | tx_id
)

pv "VOTE_ID" VOTE_ID

echo "Waiting for: vote to be included in a block" | cb
sleep 1

echo "\n ✨INFO: Ensuring no errors in transaction" | cb
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
echo -n "Raw Log: "
echo "$TX_JSON" | jq '.raw_log'

echo "\n ✨INFO: Getting the Proposal Votes Information and see that vote was not effective" | cb
VOTES_INFO=$(zigchaind q gov tally $PROPOSAL_ID --output json)

echo $VOTES_INFO

# --------------------------------------------------------------------------------------------
# ACCOUNT Z VOTES ON THE PROPOSAL
# --------------------------------------------------------------------------------------------

echo "\n 🚀 EXEC: $ACCOUNT_Z votes YES on the proposal" | cb
echo "This vote is effective as he is staking" | cb

VOTE_Z_ID=$(
  zigchaind tx gov vote $PROPOSAL_ID yes \
    --from=$ACCOUNT_Z \
    $TX_FLAGS_NO_GAS_ADJ --gas-adjustment 2 -y --output json | tx_id
)

pv "VOTE_Z_ID" VOTE_Z_ID

echo "Waiting for: vote to be included in a block" | cb
sleep 1

echo "\n ✨INFO: Ensuring no errors in transaction" | cb
TX_JSON=$(zigchaind q tx "$VOTE_Z_ID" --output json)
echo -n "Raw Log: "
echo "$TX_JSON" | jq '.raw_log'

echo "\n ✨INFO: Getting the Proposal Votes Information and see that vote was effective" | cb
VOTES_INFO=$(zigchaind q gov tally $PROPOSAL_ID --output json)

echo $VOTES_INFO

