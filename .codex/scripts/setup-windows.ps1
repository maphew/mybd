$ErrorActionPreference = "Stop"

Write-Host "Preparing Codex workspace at A:\dev\mybd"

if (-not (Test-Path ".\main")) {
    throw "Expected .\main to exist."
}

if (Test-Path ".\main\go.mod") {
    Write-Host "Found Go module under .\main"
}

if (Get-Command bd -ErrorAction SilentlyContinue) {
    Write-Host "Running bd prime from repo root"
    bd prime
} else {
    Write-Host "bd is not on PATH; skipping bd prime"
}
