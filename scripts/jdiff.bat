@echo off
:: JSON Diff Script for Windows
:: Usage: jdiff file1.json file2.json

if "%~1"=="" (
    echo Usage: jdiff file1.json file2.json
    exit /b 1
)

if "%~2"=="" (
    echo Usage: jdiff file1.json file2.json
    exit /b 1
)

if not exist "%~1" (
    echo Error: File %~1 not found
    exit /b 1
)

if not exist "%~2" (
    echo Error: File %~2 not found
    exit /b 1
)

gojq --argfile a "%~1" --argfile b "%~2" -n ^
"$a as $file1 | $b as $file2 | ^
$file1 | to_entries | map( ^
  select(.value != $file2[.key]) | ^
  \"Key: \(.key)\n  %~nx1: \(.value)\n  %~nx2: \($file2[.key])\n\" ^
)"