#!/usr/bin/env pwsh

# Copyright 2026 Michael F. Collins, III
# Licensed under the Naked Time license. See LICENSE.md for details.

$variableName = 'pnpm_config_allow_builds'
$previousValue = [Environment]::GetEnvironmentVariable($variableName, 'Process')
[Environment]::SetEnvironmentVariable($variableName, '{"esbuild":true}', 'Process')

try {
    & aspire run
    $exitCode = $LASTEXITCODE
}
finally {
    [Environment]::SetEnvironmentVariable($variableName, $previousValue, 'Process')
}

exit $exitCode
