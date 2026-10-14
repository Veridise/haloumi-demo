#!/bin/bash 

set -e

sha3_repo_dir=sha3-circuit
patch_file=$(realpath sha3-circuit.patch)

pushd $sha3_repo_dir 

git add -A
git diff --cached > $patch_file
git reset

popd
