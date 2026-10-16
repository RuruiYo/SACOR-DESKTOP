param(
    [string]$ApiUrl = 'http://localhost:5084',
    [string]$ApiKey = '',
    [switch]$Demo
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not $Demo -and -not $ApiKey) {
    Write-Warning 'Sin -ApiKey: la app pedirá la llave en sacor_config.json antes de poder entrar.'
}

flutter pub get
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Las pruebas fallaron; no se compila.' }

flutter build windows --release "--dart-define=SACOR_DEMO=$($Demo.IsPresent.ToString().ToLower())"
if ($LASTEXITCODE -ne 0) { throw 'La compilación falló.' }

$salida = 'build\windows\x64\runner\Release'
$config = [ordered]@{ apiUrl = $ApiUrl; apiKey = $ApiKey; modoDemo = $Demo.IsPresent }
$config | ConvertTo-Json | Out-File -Encoding utf8 (Join-Path $salida 'sacor_config.json')

foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    $origen = Join-Path $env:WINDIR "System32\$dll"
    if (Test-Path $origen) { Copy-Item $origen $salida -Force }
}

$zip = 'build\SACOR.Desktop.zip'
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path "$salida\*" -DestinationPath $zip

Write-Host ''
Write-Host "Listo: $salida\SACOR.Desktop.exe"
Write-Host "Para entregar: $zip (descomprimir en la otra PC y abrir SACOR.Desktop.exe)."
