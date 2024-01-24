#!/bin/bash

# Args:
# 1 --> Start block idx
# 2 --> End block index (inclusive)
# 3 --> Rpc endpoint:port (eg. http://35.246.1.96:8545)
# 4 --> Ignore previous proofs (boolean)

export RUST_BACKTRACE=1
export RUST_LOG=plonky2=info,plonky2_evm=info,protocol_decoder=info

export ARTITHMETIC_CIRCUIT_SIZE="16..17"
export BYTE_PACKING_CIRCUIT_SIZE="9..18"
export CPU_CIRCUIT_SIZE="12..21"
export KECCAK_CIRCUIT_SIZE="14..16"
export KECCAK_SPONGE_CIRCUIT_SIZE="9..13"
export LOGIC_CIRCUIT_SIZE="12..15"
export MEMORY_CIRCUIT_SIZE="17..24"

PROOF_OUTPUT_DIR="proofs"
ALWAYS_WRITE_LOGS=0 # Change this to `1` if you always want logs to be written.

TOT_BLOCKS=$(($2-$1+1))

mkdir -p proofs/

for ((i=$1; i<=$2; i++))
do
    echo "Proving block ${i}..."

    out_idx=$(printf "%05d" $i)

    WORKING_DIR=$(pwd)
    OUT_PROOF_PATH="${PROOF_OUTPUT_DIR}/b${out_idx}.zkproof"
    OUT_LOG_PATH="${PROOF_OUTPUT_DIR}/b${out_idx}.log"
    PROOF_FILE_NAME="${WORKING_DIR}/${OUT_PROOF_PATH}"

    # Set checkpoint height to previous block number
    prev_proof_num=$((i-1))
    CHECKPOINT_ARG="--checkpoint-block-number ${prev_proof_num}"

    cargo r --release --bin leader -- \
	  --runtime in-memory jerigon \
	  --rpc-url "$3" \
	  --block-number $i \
	  --proof-output-path $OUT_PROOF_PATH \
	  $CHECKPOINT_ARG > $OUT_LOG_PATH 2>&1

    if [[ -e $OUT_PROOF_PATH ]]; then
        echo "Successfully generated proof for block ${i}! (proof available at $PROOF_FILE_NAME)!"
        if [[ $ALWAYS_WRITE_LOGS -ne 1 ]]; then
            rm $OUT_LOG_PATH
        fi
    else
	echo "Block ${i} errored. See ${OUT_LOG_PATH} for more details."
	exit 1
    fi
done
