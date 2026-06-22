param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Rest
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$agentSig = Join-Path $scriptDir 'agent-sig'
$gitBash = Join-Path ${env:ProgramFiles} 'Git\bin\bash.exe'

if (-not (Test-Path -LiteralPath $gitBash)) {
    $bashCommand = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($null -eq $bashCommand) {
        throw "Git Bash not found. Install Git for Windows or run scripts/agent-sig through an available bash.exe."
    }
    $gitBash = $bashCommand.Source
}

& $gitBash $agentSig @Rest
exit $LASTEXITCODE
