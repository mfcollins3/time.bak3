#!/usr/bin/env bash

# Copyright 2026 Michael F. Collins, III
# Licensed under the Naked Time license. See LICENSE.md for details.

set -e

if ! command -v fnm > /dev/null; then
    echo "error: fnm is required but was not found. See README.md for prerequisites." >&2
    exit 1
fi

if ! command -v mix > /dev/null; then
    echo "error: Elixir is required but was not found. See README.md for prerequisites." >&2
    exit 1
fi

# Activate fnm in this script and switch to the Node.js version in
# .node-version, downloading it if necessary.
eval "$(fnm env)"
fnm use --install-if-missing

# On macOS, use mise to ensure that tuist is installed for building the
# Apple applications. See .mise.toml for the pinned version.
if [ "$(uname -s)" = "Darwin" ]; then
    if ! command -v mise > /dev/null; then
        echo "error: mise is required on macOS but was not found. See README.md for prerequisites." >&2
        exit 1
    fi

    mise install
fi

pushd src/apphost > /dev/null
pnpm install
popd > /dev/null

# Fetch the web application's Elixir dependencies, then install its Node.js
# packages for Vite. The Node.js packages include phoenix, phoenix_html,
# phoenix_live_view and phoenix_vite from deps/, so the Elixir dependencies
# must be fetched first.
pushd src/web > /dev/null
mix deps.get
mix assets.setup
popd > /dev/null
