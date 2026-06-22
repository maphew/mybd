param(
    [Parameter(Mandatory = $true)]
    [string] $ScriptName,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Rest
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir $ScriptName

if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "Script not found: $target"
}

$firstLine = Get-Content -LiteralPath $target -TotalCount 1

if ($firstLine -match '\bbash\b') {
    $bash = Join-Path ${env:ProgramFiles} 'Git\bin\bash.exe'
    if (-not (Test-Path -LiteralPath $bash)) {
        $bashCommand = Get-Command bash.exe -ErrorAction SilentlyContinue
        if ($null -eq $bashCommand) {
            throw "Git Bash not found. Install Git for Windows or run $target through an available bash.exe."
        }
        $bash = $bashCommand.Source
    }

    & $bash $target @Rest
    exit $LASTEXITCODE
}

if ($firstLine -match '\bpython3?\b') {
    $pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($null -eq $pythonCommand) {
        $pythonCommand = Get-Command py.exe -ErrorAction SilentlyContinue
    }
    if ($null -eq $pythonCommand) {
        throw "Python not found. Install Python or run $target through an available python executable."
    }

    & $pythonCommand.Source $target @Rest
    exit $LASTEXITCODE
}

throw "Unsupported shebang in ${target}: $firstLine"
