#!/usr/bin/env pwsh

# Copyright 2026 Michael F. Collins, III
# Licensed under the Naked Time license. See LICENSE.md for details.

if (-not (Get-Command fnm -ErrorAction SilentlyContinue)) {
    Write-Error 'fnm is required but was not found. See README.md for prerequisites.'
    exit 1
}

$fnmEnvironment = & fnm env --shell powershell
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Invoke-Expression ($fnmEnvironment -join [Environment]::NewLine)
& fnm use --install-if-missing
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# On macOS, use mise to ensure that tuist is installed for building the
# Apple applications. See .mise.toml for the pinned version.
if ($IsMacOS) {
    if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
        Write-Error 'mise is required on macOS but was not found. See README.md for prerequisites.'
        exit 1
    }

    Push-Location $PSScriptRoot
    try {
        & mise install
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    finally {
        Pop-Location
    }
}

$appHostPath = Join-Path $PSScriptRoot 'src/apphost'
Push-Location $appHostPath

try {
    & pnpm install
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

exit $exitCode
