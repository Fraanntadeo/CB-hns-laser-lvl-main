# backup_db.ps1 - Respalda la base de datos SQLite de cuentas
# Uso: ejecutar en PowerShell: .\backup_db.ps1

$src = Join-Path $PSScriptRoot "..\data\sqlite3\cuentas.sq3"
$src = Resolve-Path $src
if (-not (Test-Path $src)) {
    Write-Error "Archivo de BD no encontrado: $src"
    exit 1
}

$ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
$destDir = Join-Path $PSScriptRoot "..\backups"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }

$dest = Join-Path $destDir "cuentas_$ts.sq3"
Copy-Item -Path $src -Destination $dest -Force
Write-Output "Backup creado: $dest"
