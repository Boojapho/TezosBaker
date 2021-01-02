# Nodecheck

Nodecheck will query the tezos node RPC at localhost:8723 for the health of the node.  It performs the following:

- Verify that the number of peers is > 1
- Verify that the head block has changed from the last nodecheck

## Usage

This is intended to be used as a liveness check for a tezos-node.  If the liveness check fails, the node should be considered inoperable and restarted.  The check should be run at an interval > the amount of time it takes for new blocks to be generated on the tezos node

There are no arguments.  Run `./nodecheck` to execute

## Assumptions

- RPC is located at http://localhost:8732
- Node data dir is at /var/lib/tezos/node 

## State

This program stores two files in the node's data directory to maintain state between runs:

- `last_block` - holds the level of the block validated by the node on the last run of nodecheck.  This is compared to the current block from the RPC to validate the block is changing.
- `resync` - if the number of peers is > 1, but the last block isn't changing, this file is created to indicate the node's data should be resynced.  An init container could be used to handle this situation.

## Exit codes

On success, the program exits with code 0.
On failure, the program exits with code 1.

### Building

1. Install [GoLang](https://golang.org/): `sudo apt install golang-go`
1. Compile with CGO disabled to produce a statically linked executable: `CGO_ENABLED=0 go build`
1. Run: `./nodecheck`

