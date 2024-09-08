#! /usr/bin/env bash
# reproduce the documented user journey for installing and running rodiff
# this is run in the CI pipeline, non-zero exit code indicates a failure

set -o pipefail
set -eux

# fetch the odiff executables
bundle exec rake download

# Get the directory of the current script
CURRENT_DIR="$(dirname "$0")"
pushd "$CURRENT_DIR"

# switch to working directory
rm -rf "My Bundle"
mkdir "My Bundle"
pushd "My Bundle"

cp ../tiger.jpg .
cp ../tiger-2.jpg .

bundle info rodiff
bundle show --paths

# TEST: odiff was installed correctly
bundle exec rodiff ./tiger.jpg ./tiger-2.jpg diff.png