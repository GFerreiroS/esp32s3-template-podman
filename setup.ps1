# Requires PowerShell 5+ or PowerShell Core
# Run this script from the project root

$ErrorActionPreference = "Stop"
$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VSDir = "$WorkDir\.vscode"
$EnvFile = "$VSDir\env.json"
$CCPPFile = "$VSDir\c_cpp_properties.json"

if ((docker ps 2>&1) -match '^(?!error)'){
    Write-Error "Docker does not appear to be running. Please start Docker and try again."
    exit 1
}

if (-not (Test-Path $VSDir)) { New-Item -ItemType Directory -Force -Path $VSDir | Out-Null }

Write-Host "=== ESP32-S3 Project Setup ===`n"

# 1) Detect or ask for serial port
$DefaultPort = "COM3"
try {
    $Ports = Get-WmiObject Win32_SerialPort | Select-Object -ExpandProperty DeviceID
    if ($Ports.Count -gt 0) { $DefaultPort = $Ports[0] }
} catch {}
$Port = Read-Host "Enter serial port [default: $DefaultPort]"
if (-not $Port) { $Port = $DefaultPort }

# 2) Ask whether to open menuconfig
$Menu = Read-Host "Launch menuconfig now? [y/N]"
if (-not $Menu) { $Menu = "n" }

# 3) Ask whether to set up IntelliSense
$Intelli = Read-Host "Set up IntelliSense (mirror IDF headers + update include paths)? [Y/n]"
if (-not $Intelli) { $Intelli = "y" }

$HeaderPath = ""
if ($Intelli -match "^[Yy]$") {
    $DefaultHeaderPath = "$HOME/.idf-sysroot/idf"
    $HeaderPath = Read-Host "Path to mirror ESP-IDF headers [$DefaultHeaderPath]"
    if (-not $HeaderPath) { $HeaderPath = $DefaultHeaderPath }

    $HeaderParent = Split-Path $HeaderPath -Parent
    if (-not (Test-Path $HeaderParent)) { New-Item -ItemType Directory -Force -Path $HeaderParent | Out-Null }

    Write-Host "`n[*] Syncing ESP-IDF headers to $HeaderPath ...`n"
    docker run --rm -it `
        -v "${HeaderParent}:/host-idf:z" `
        espressif/idf:latest `
        bash -lc "rm -rf /host-idf/idf && cp -a /opt/esp/idf /host-idf/"
    Write-Host "[*] Header mirror complete.`n"
}

# 4) Save env.json
@"
{
  "serialPort": "$Port",
  "idfHeaderPath": "$HeaderPath"
}
"@ | Set-Content -Path $EnvFile -Encoding UTF8
Write-Host "[*] Saved configuration to $EnvFile"

# 5) Update c_cpp_properties.json if IntelliSense enabled
if (($Intelli -match "^[Yy]$") -and (Test-Path $CCPPFile)) {
    Write-Host "[*] Updating include path in c_cpp_properties.json"
    $json = Get-Content $CCPPFile -Raw | ConvertFrom-Json
    $paths = $json.configurations[0].includePath
    $newPaths = @()
    foreach ($p in $paths) {
        if ($p -match "idf/components") {
            $newPaths += "$HeaderPath/components/**"
        } else {
            $newPaths += $p
        }
    }
    $json.configurations[0].includePath = $newPaths
    $json | ConvertTo-Json -Depth 6 | Set-Content -Path $CCPPFile -Encoding UTF8
}

# 6) Create sdkconfig from defaults
Write-Host "[*] Generating sdkconfig..."
docker run --rm -it `
    -v "${WorkDir}:/work:z" -v "$HOME/.espressif:/root/.espressif:z" `
    -w /work espressif/idf:latest `
    bash -lc "idf.py set-target esp32s3"

# 7) Optionally open menuconfig
if ($Menu -match "^[Yy]$") {
    Write-Host "[*] Launching menuconfig..."
    docker run --rm -it `
        -e TERM=xterm-256color `
        -v "${WorkDir}:/work:z" -v "$HOME/.espressif:/root/.espressif:z" `
        -w /work espressif/idf:latest `
        bash -lc "idf.py -B build menuconfig"
}

Write-Host "`nSetup complete."
Write-Host "Serial port: $Port"
if ($Intelli -match "^[Yy]$") { Write-Host "IntelliSense headers: $HeaderPath" }
Write-Host ""
