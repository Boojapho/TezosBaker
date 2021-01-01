# Peercheck

Peercheck will query the tezos node RPC at localhost:8723 to get the number of connected peers.  It exits with an error if the number of connections is 1 or less.  If there are no peers, the number of connections will be 1. 

## Exit codes

When the number of peers is > 1, the program exits successfully (0).
When the number of peers is <= 1, the program exits with an error (1).

## Usage

This is intended to be used as a liveness check for a tezos-node.  If the liveness check fails, the node should be considered inoperable and restarted.

### Prerequisites
- [GoLang](https://golang.org/) - sudo apt install golang-go

### Compile
`go build`

### Run
`./peercheck`
