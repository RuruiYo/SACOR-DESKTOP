param(
    [string]$RutaApi = "$env:USERPROFILE\source\repos\API_SACOR",
    [string]$Base = "sacor_local",
    [int]$Puerto = 5084,
    [int]$PuertoWeb = 7357
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$proyecto = Join-Path $RutaApi "APISacor"
if (-not (Test-Path (Join-Path $proyecto "APISacor.csproj"))) {
    throw "No encontré APISacor.csproj en $proyecto. Indicá la carpeta de la API con -RutaApi."
}

$archivoLlave = Join-Path $PSScriptRoot "llave_local.txt"
if (-not (Test-Path $archivoLlave)) {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    ($bytes | ForEach-Object { $_.ToString("x2") }) -join "" | Set-Content $archivoLlave -NoNewline -Encoding ASCII
}
$llave = (Get-Content $archivoLlave -Raw).Trim()

$config = [ordered]@{ apiUrl = "http://localhost:$Puerto"; apiKey = $llave }
$config | ConvertTo-Json | Set-Content (Join-Path $raiz "sacor_config.json") -Encoding UTF8

$env:ConnectionStrings__SacorDb = "Server=(localdb)\MSSQLLocalDB;Database=$Base;Trusted_Connection=True;TrustServerCertificate=True"
$env:Seguridad__ApiKeys__AppEscritorio = $llave
$env:Seguridad__OrigenesPermitidos__0 = "http://localhost:$PuertoWeb"
$env:ASPNETCORE_ENVIRONMENT = "Development"

Write-Host "API de SACOR en http://localhost:$Puerto (base $Base). Ctrl+C para detenerla."
Write-Host "Vista previa web permitida desde http://localhost:$PuertoWeb"
dotnet run --project $proyecto --no-launch-profile --urls "http://localhost:$Puerto"
