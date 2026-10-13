param(
    [string]$RutaApi = "$env:USERPROFILE\source\repos\API_SACOR",
    [string]$Base = "sacor_local",
    [string]$Servidor = "(localdb)\MSSQLLocalDB",
    [switch]$SinDatos
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$scriptTablas = Join-Path $RutaApi "db\sacor_db.sql"
$scriptDatos = Join-Path $PSScriptRoot "datos_prueba.sql"

if ($Base -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw "Nombre de base inválido: $Base" }
if ($Base -eq "sacor") { throw "Usá otro nombre (por ejemplo sacor_local) para no confundirla con la base real." }
if (-not (Test-Path $scriptTablas)) { throw "No encontré $scriptTablas. Indicá la carpeta de la API con -RutaApi." }
if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) { throw "No encontré sqlcmd en el PATH." }

Write-Host "Iniciando LocalDB..."
sqllocaldb start MSSQLLocalDB | Out-Null

$temporal = Join-Path $env:TEMP "sacor_tablas_$Base.sql"
(Get-Content $scriptTablas -Raw -Encoding UTF8) `
    -replace "DB_ID\('sacor'\)", "DB_ID('$Base')" `
    -replace "CREATE DATABASE sacor;", "CREATE DATABASE $Base;" `
    -replace "USE sacor;", "USE $Base;" |
    Set-Content $temporal -Encoding UTF8

Write-Host "Creando tablas en $Servidor / $Base (borra las que ya existan en esa base)..."
sqlcmd -S $Servidor -E -b -f 65001 -I -i $temporal
if ($LASTEXITCODE -ne 0) { throw "Falló la creación de tablas." }
Remove-Item $temporal

if (-not $SinDatos) {
    Write-Host "Cargando datos de prueba..."
    sqlcmd -S $Servidor -E -b -f 65001 -I -d $Base -i $scriptDatos
    if ($LASTEXITCODE -ne 0) { throw "Falló la carga de datos de prueba." }
}

Write-Host ""
Write-Host "Listo. Base: $Servidor / $Base"
if (-not $SinDatos) { Write-Host "Código del administrador de prueba: 482913" }
Write-Host "Siguiente paso: .\herramientas\api_local.ps1"
