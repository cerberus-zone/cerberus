#!/bin/bash
# microtick and bitcanna contributed significantly here.
# Pebbledb state sync script.
# invoke like: bash scripts/ss.bash
set -uxe

# Set Golang environment variables.
export GOPATH=~/go
export PATH=$PATH:~/go/bin

# Install with pebbledb 
go mod edit -replace github.com/tendermint/tm-db=github.com/baabeetaa/tm-db@pebble
go mod tidy
go install -ldflags '-w -s -X github.com/cosmos/cosmos-sdk/types.DBBackend=pebbledb -X github.com/tendermint/tm-db.ForceSync=1 -X github.com/cosmos/cosmos-sdk/version.Version=v0.26.0' -tags pebbledb ./...

# go install ./...

# NOTE: ABOVE YOU CAN USE ALTERNATIVE DATABASES, HERE ARE THE EXACT COMMANDS
# go install -ldflags '-w -s -X github.com/cosmos/cosmos-sdk/types.DBBackend=rocksdb' -tags rocksdb ./...
# go install -ldflags '-w -s -X github.com/cosmos/cosmos-sdk/types.DBBackend=badgerdb' -tags badgerdb ./...
# go install -ldflags '-w -s -X github.com/cosmos/cosmos-sdk/types.DBBackend=boltdb' -tags boltdb ./...

rm -f ~/.cerberus/config/genesis.json

# Initialize chain.
cerberusd init test

# Get Genesis
wget https://raw.githubusercontent.com/cerberus-zone/cerberus_genesis/main/genesis.json -O genesis.json
mv genesis.json ~/.cerberus/config/genesis.json


# Get "trust_hash" and "trust_height".
INTERVAL=1000
LATEST_HEIGHT=$(curl -s https://cerberus-rpc.polkachu.com/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$(($LATEST_HEIGHT-$INTERVAL)) 
TRUST_HASH=$(curl -s "https://cerberus-rpc.polkachu.com/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

# Print out block and transaction hash from which to sync state.
echo "trust_height: $BLOCK_HEIGHT"
echo "trust_hash: $TRUST_HASH"

# Export state sync variables.
export AXELARD_STATESYNC_ENABLE=true
export AXELARD_P2P_MAX_NUM_OUTBOUND_PEERS=200
export AXELARD_STATESYNC_RPC_SERVERS="https://cerberus-rpc.polkachu.com:443,https://cerberus-rpc.polkachu.com:443"
export AXELARD_STATESYNC_TRUST_HEIGHT=$BLOCK_HEIGHT
export AXELARD_STATESYNC_TRUST_HASH=$TRUST_HASH

# Fetch and set list of seeds from chain registry.
export AXELARD_P2P_SEEDS=$(curl -s https://raw.githubusercontent.com/cosmos/chain-registry/master/cerberus/chain.json | jq -r '[foreach .peers.seeds[] as $item (""; "\($item.id)@\($item.address)")] | join(",")')

# Start chain.
cerberusd start --x-crisis-skip-assert-invariants --db_backend pebbledb