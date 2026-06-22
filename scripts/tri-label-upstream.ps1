$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir '_invoke-shebang.ps1') 'tri-label-upstream' @args
exit $LASTEXITCODE
