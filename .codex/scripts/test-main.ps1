$ErrorActionPreference = "Stop"

Push-Location ".\main"
try {
    go test ./...
} finally {
    Pop-Location
}
