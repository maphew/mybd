$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir '_invoke-shebang.ps1') 'md2html' @args
exit $LASTEXITCODE
