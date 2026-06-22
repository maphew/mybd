$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir '_invoke-shebang.ps1') 'tri-checkpoint' @args
exit $LASTEXITCODE
