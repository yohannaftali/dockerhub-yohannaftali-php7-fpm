# Wrapper: .\scripts\dockerhub-update.ps1 [sync|status|tags|delete-tag <tag>]
$ErrorActionPreference = 'Stop'
uv run (Join-Path $PSScriptRoot 'dockerhub_update.py') @args
exit $LASTEXITCODE
