# Haloumi Demo

This tarball contains the necessary ingredients for preparing a demo of extracting Keccak using Haloumi.

## Setup

Run the `prepare.sh` script to prepare the environment. This script will:

1. Clone the `sha3-circuit` repo completely vanilla.
2. Apply a patch that adds the extraction harnesses and Haloumi's configuration.
3. Clone Haloumi (necessary for running the top-level CLI tool).

Once the script completes, go to `haloumi` and run `direnv allow` to allow Nix to install LLZK.

To check that everything builds properly, run the following command:

```
RUST_LOG=info cargo run -p cargo-haloumi -- --root ../sha3-circuit --dry-run
```

That command will build Haloumi's CLI and then build the extractor on the fly, applying the configuration.
The `--root` flag sets the directory where the target crate is located. By default is the current directory and that's 
the intended location to run the tool, but since the current version is built locally is easier to run it from 
`haloumi` directory and set the root to the target.

The `--dry-run` flag stops the tool right before extracting. To actually run the extractor, run the same command again but without the `--dry-run` flag.

## What's Happening While the Tool Runs

1. The `sha3-circuit` crate is copied to a temporary workspace under `sha3-circuit/target/haloumi/.crates`.
2. The tool looks for patchable dependencies (in this case, `midnight-proofs`) and applies the patches from the spec files defined in `sha3-circuit/.haloumi/specs`.
3. It injects a runner binary that loads all the harnesses and runs the extractor (similar in concept to `cargo test`).
4. It compiles and executes the runner binary.
5. The extractor inside the runner synthesizes the circuit defined in each harness and emits the IR.
6. The generated IR is in `target/haloumi/llzk` for LLZK and `target/haloumi/picus` for Picus.

### Outputs

I don't think there'll be enough time to show the extractor running end to end, but for completeness, I'm describing it a bit here.

With the current configuration, the extractor will generate the LLZK representation of each circuit. Then, to convert that LLZK to PCL, you'd have to use `llzk-opt` and `llzk-translate`. My plan is to automate that inside Haloumi's CLI.

## Stuff to Highlight Inside `sha3-circuit`

### `.haloumi/specs/midnight-proofs.toml`

This is the configuration for integrating their Halo2 crate with Haloumi. The sales pitch is that the tool will apply those patches on the fly and that they no longer need to be manually added to their Halo2 crate.

### `.haloumi/cfg.toml`

This is the main configuration file. It should be good to go for the demo; there's no need to touch anything.

### `src/sha3_256_gadget.rs` Lines 234–359

This is one of the harnesses that we ported from the old extractor. The new model revolves around defining the harnesses next to the circuit itself. We plan to leverage macros similar to the one used for defining groups (`picus::group`).

### `src/lib.rs`

This includes supporting code for working with their lookups, including the code that gets injected to represent every lookup and the special Picus modules `Spread` and `Unspread`.

It also includes the gate callbacks (the `gate_callbacks` module), which every harness passes to `extract_circuit_with_callbacks`. The packed Keccak chip splits noisy spread words into clean parts with its `"bootstrap constraint"` gate, `acc[r+1] = 2·acc[r] + part[r+1]`. Picus can't derive that the parts are unique from range bounds alone, so on each row where the gate is enabled, the `BootstrapAxioms` pattern emits the gate's constraint plus one axiom:

```
det(acc[r+1]) → det(acc[r]) ∧ det(part[r+1])
```

The pattern reads the cells off the gate's polynomial and fails if the polynomial has any other shape. `keccakf` gets 2,065 of these axioms, which replace about 550K lookup-based ones, and `keccakf` and `sha3/digest_1` both verify in Picus. Gate callbacks need Haloumi [PR #33](https://github.com/project-llzk/haloumi/pull/33); `prepare.sh` checks out that branch.
