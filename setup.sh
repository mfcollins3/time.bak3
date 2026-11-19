#!/usr/bin/env bash

# Copyright 2026 Michael F. Collins, III
# Licensed under the Naked Time license. See LICENSE.md for details.

set -e

if ! command -v fnm > /dev/null; then
    echo "error: fnm is required but was not found. See README.md for prerequisites." >&2
    exit 1
fi

# Activate fnm in this script and switch to the Node.js version in
# .node-version, downloading it if necessary.
eval "$(fnm env)"
fnm use --install-if-missing

pushd src/apphost > /dev/null
pnpm install
popd > /dev/null
