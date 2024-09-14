#! /usr/bin/env bash
# reproduce the documented user journey for installing and running rodiff
# this is run in the CI pipeline, non-zero exit code indicates a failure

set -o pipefail
set -eux

# set up dependencies
rm -f Gemfile.lock
bundle install

# Get the directory of the current script
CURRENT_DIR="$(dirname "$0")"
pushd "$CURRENT_DIR"

# switch to working directory
rm -rf "My Npm"
mkdir "My Npm"
pushd "My Npm"

cp ../tiger.jpg .

# set up dependencies
rm -f package.json package-lock.json
npm install odiff-bin

# TEST: odiff was installed correctly
npx -v
npx --loglevel verbose odiff-bin tiger.jpg tiger.jpg diff.png

# use the rodiff under test
bundle info rodiff
bundle show --paths

# TEST: odiff executable was not configured
OUTPUT=$(bundle exec rodiff tiger.jpg tiger.jpg diff.png 2>&1 || true)
echo "$OUTPUT" | fgrep "ERROR: Cannot find the odiff executable for"

# TEST: odiff was linked with relative path
OUTPUT=$(ODIFF_INSTALL_DIR="./node_modules/.bin" bundle exec rodiff tiger.jpg tiger.jpg diff.png 2>&1)
echo "$OUTPUT" | fgrep "NOTE: using ODIFF_INSTALL_DIR to find odiff executable: ./node_modules/.bin"

# TEST: odiff was linked with absolute path
ODIFF_BIN=$(realpath "./node_modules/odiff-bin/bin")
OUTPUT=$(ODIFF_INSTALL_DIR=$ODIFF_BIN bundle exec rodiff tiger.jpg tiger.jpg diff.png 2>&1)
echo "$OUTPUT" | egrep "NOTE: using ODIFF_INSTALL_DIR to find odiff executable: .+?/odiff-bin/bin"