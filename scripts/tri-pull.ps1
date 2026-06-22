$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir '_invoke-shebang.ps1') 'tri-pull' @args
exit $LASTEXITCODE
