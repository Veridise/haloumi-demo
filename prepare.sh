#!/bin/bash 

set -e

sha3_repo_dir=sha3-circuit
sha3_repo=https://github.com/alexandroszacharakis8/$sha3_repo_dir
skel=$(realpath envrc.skel)

echo Installing cargo-haloumi...
cargo install cargo-haloumi

if ! [ -f sha3-circuit.patch ] ; then 
  echo Patch file is missing!
  exit 1
fi

if ! [ -e $sha3_repo_dir ] ; then 
  echo Cloning circuit repository...
  git clone --depth=1 $sha3_repo
  pushd $sha3_repo_dir
  echo Applying patch
  git apply ../sha3-circuit.patch

  echo Adding .envrc file 
  cp $skel .envrc
  echo Allowing environment
  direnv allow

  popd 
fi


echo =====================================================================
echo Environment ready for the demo.
echo =====================================================================
