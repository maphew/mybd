$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir '_invoke-shebang.ps1') 'pre-commit-beads-config' @args
exit $LASTEXITCODE
