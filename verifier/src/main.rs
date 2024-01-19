use std::fs::File;

use anyhow::Result;
use clap::Parser;
use common::prover_state::{set_prover_state_from_config, P_STATE};
use plonky_block_proof_gen::{prover_state::ProverState, types::PlonkyProofIntern};
use serde_json::Deserializer;
use tracing::warn;

mod cli;
mod init;

fn p_state() -> &'static ProverState {
    P_STATE.get().expect("Prover state is not initialized")
}

fn main() -> Result<()> {
    init::tracing();

    let args = cli::Cli::parse();
    let file = File::open(args.file_path)?;
    let des = &mut Deserializer::from_reader(&file);
    let input: PlonkyProofIntern = serde_path_to_error::deserialize(des)?;

    if set_prover_state_from_config(args.prover_state_config.into()).is_err() {
        warn!("prover state already set. check the program logic to ensure it is only set once");
    }

    p_state().state.verify_block(&input)?;

    Ok(())
}
