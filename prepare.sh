#!/bin/bash 

sha3_repo_dir=sha3-circuit
sha3_repo=https://github.com/alexandroszacharakis8/$sha3_repo_dir



if ! [ -f sha3-circuit.patch ] ; then 
  echo Patch file is missing!
  exit 1
fi

if ! [ -e $sha3_repo_dir ] ; then 
  echo Cloning circuit repository...
  git clone --depth=1 $sha3_repo
  pushd $sha3_repo_dir
  git apply ../sha3-circuit.patch
  popd
fi

if ! [ -e haloumi ] ; then 
  echo Cloning haloumi...
  git clone https://github.com/project-llzk/haloumi 
  pushd haloumi 
  git checkout dani/cargo-haloumi-2
  cat > .envrc <<EOF 
if ! has nix_direnv_version || ! nix_direnv_version 3.0.4; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.4/direnvrc" "sha256-DzlYZ33mWF/Gs8DDeyjr8mnVmQGx7ASYqA5WlxwvBG4="
fi

use flake
EOF
  popd 
fi

runner=$sha3_repo_dir/target/haloumi/.cargo/release/haloumi-extractor
if ! [ -e $runner ] ; then 
  echo Building extractor in dry-run mode...
  pushd haloumi 

  echo Generated environment file:
  cat .envrc

  echo Allowing environment
  direnv allow

  #RUST_LOG=info cargo run -p cargo-haloumi -- --root ../$sha3_repo_dir --dry-run
  popd 
fi


echo =====================================================================
echo Environment ready for the demo.
echo =====================================================================
