#!/bin/bash -e

# This script will initialize a Tezos node by performing the following if needed:
# - Generate identity
# - Download a snaphot
# - Import snapshot

# Defaults
data_dir=/home/tezos/.tezos-node
snapshot_dir=/home/tezos/.tezos-snapshots
snapshot_type=rolling
snapshot_repo=https://mainnet.xtz-shots.io/$snapshot_type 
block_explorer=https://api.tzstats.com/explorer/block
resync=0

# Create directories if needed
if [[ ! -d $data_dir ]]; then
  mkdir -p $data_dir
fi
if [[ ! -d $snapshot_dir ]]; then
  mkdir -p $snapshot_dir
fi

# Generate identity - Only perform if identity.json is not found
if [[ ! -f $data_dir/identity.json ]]; then
  echo "Identity not found.  Creating..."
  tezos-node identity generate 
fi

# Check for resync file as a special indicator that the node is having issues
if [[ -f $data_dir/resync ]]; then
  if [[ -s $data_dir/resync ]]; then
    # Resync has been seen once before and acknowledged, so its time to import a snapshot
    echo "Acknowledged resync found.  Flagging resync ..."
    resync=1
  else
    # If resync is there, but empty, we tag it and let the reboot attempt to solve the issue
    echo "Resync found. Acknowledging ..."
    echo "Acknowledged" > $data_dir/resync
  fi
fi

# Check if the resync flag is set or the node is missing a critical directory
if [[ $resync -eq 1 || ! -d $data_dir/context || ! -d $data_dir/store || ! -f $data_dir/snapshot ]]; then

  echo "Node data is not healthy.  Resync required ..."

  # Get the latest snapshot (http://mywiki.wooledge.org/BashFAQ/003)
  echo "Checking for snapshots in $snapshot_dir/*.$snapshot_type"
  for file in "$snapshot_dir"/*.$snapshot_type; do
    [[ $file -nt $latest ]] && latest=$file
  done

  # Check if there is no snapshot or the latest is more than 24 hour old
  # It is possible that another script is creating snapshots here as backups
  if [[ -z $latest || $(($(date +%s) - $(stat -L -c %Y $latest))) -gt 86400 ]]; then
    
    # Download a new snapshot
    echo "No suitable snapshots found.  Downloading latest from $snapshot_repo ..."
    wget --trust-server-names -P $snapshot_dir --unlink $snapshot_repo
    
    # Get downloaded file
    for file in "$snapshot_dir"/*.$snapshot_type; do
      [[ $file -nt $latest ]] && latest=$file
    done
 
  fi
  echo "Using snapshot $latest."

  # Attempt to get block hash for validating
  echo "Getting snapshot's block hash from $block_explorer ..."
  level=`echo $latest | sed -r 's/.*-([0-9]*)\..*/\1/g'`
  bhash=`wget -q -O - $block_explorer/$level | jq -r '.hash'` 
  
  # Remove old data
  echo "Cleaning old data from node ..."
  rm -rf $data_dir/context ||: 
  rm -rf $data_dir/store ||:
  rm -f $data_dir/lock ||:
  rm -f $data_dir/snapshot ||:
  rm -f $data_dir/last_block ||:
  rm -f $data_dir/resync ||:

  # Import snapshot
  echo "Importing $latest snapshot ..."
  if [[ ! -z $bhash ]]; then
    options="--block $bhash"
  fi
  echo tezos-node snapshot import $latest $options
  tezos-node snapshot import $latest $options

  # Save snapshot imported to file to signify successful import
  echo $latest > $data_dir/snapshot
fi
echo "Node initialized"
