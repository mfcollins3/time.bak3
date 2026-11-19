#!/usr/bin/env bash

# Copyright 2026 Michael F. Collins, III
# Licensed under the Naked Time license. See LICENSE.md for details.

set -e

pnpm_config_allow_builds='{"esbuild":true}' aspire run
