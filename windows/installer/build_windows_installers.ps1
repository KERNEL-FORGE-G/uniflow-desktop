# ==============================================================================
# Script PowerShell d'automatisation des packages Windows UniFlow
# Génère :
#   - 1. Exécutable Setup autonome : UniFlow-1.0.0-Setup.exe (Inno Setup)
#   - 2. Package Windows Installer : UniFlow-1.0.0.msi (WiX Toolset)
#   - 3. Package Microsoft Store / MSIX : UniFlow-1.0.0.msix (MSIX Tool)
# ==============================================================================

param (
    [string]$Version = "1.0.0",
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== CONSTRUCTION DES INSTALLATEURS WINDOWS UNIFLOW (V$Version) ===" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\..\.."
$OutputDir = "$ProjectRoot\build\windows\dist"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 1. Compilation Flutter Windows Release si demandée
if (-not $SkipBuild) {
    Write-Host "`n[1/4] Compilation Flutter Windows Release..." -ForegroundColor Yellow
    Set-Location $ProjectRoot
    flutter build windows --release
}

# 2. Génération de l'installateur EXE via Inno Setup
Write-Host "`n[2/4] Génération de l'installateur .EXE via Inno Setup..." -ForegroundColor Yellow
$InnoPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $InnoPath) {
    & $InnoPath "$ScriptDir\uniflow_installer.iss"
    Copy-Item "$ProjectRoot\build\windows\installer\UniFlow-$Version-Setup.exe" -Destination "$OutputDir\" -Force
    Write-Host "✓ Fichier EXE généré : $OutputDir\UniFlow-$Version-Setup.exe" -ForegroundColor Green
} else {
    Write-Warning "Inno Setup 6 non trouvé à l'emplacement standard ($InnoPath). L'étape EXE sera exécutée dans le workflow GitHub Actions."
}

# 3. Génération du package MSI via WiX Toolset
Write-Host "`n[3/4] Génération du package .MSI via WiX Toolset..." -ForegroundColor Yellow
$CandlePath = "candle.exe"
$LightPath = "light.exe"
if (Get-Command $CandlePath -ErrorAction SilentlyContinue) {
    & $CandlePath -out "$OutputDir\uniflow.wixobj" "$ScriptDir\uniflow_installer.wxs"
    & $LightPath -out "$OutputDir\UniFlow-$Version.msi" "$OutputDir\uniflow.wixobj" -ext WixUIExtension
    Write-Host "✓ Fichier MSI généré : $OutputDir\UniFlow-$Version.msi" -ForegroundColor Green
} else {
    Write-Warning "WiX Toolset (candle/light) non trouvé dans le PATH. L'étape MSI sera exécutée dans le workflow GitHub Actions."
}

# 4. Génération du package MSIX Microsoft Store
Write-Host "`n[4/4] Génération du package .MSIX pour Microsoft Store..." -ForegroundColor Yellow
Set-Location $ProjectRoot
try {
    flutter pub run msix:create --output-path "$OutputDir" --output-name "UniFlow-$Version"
    Write-Host "✓ Fichier MSIX généré : $OutputDir\UniFlow-$Version.msix" -ForegroundColor Green
} catch {
    Write-Warning "msix:create a rencontré un avertissement : $_"
}

Write-Host "`n=== PACKAGING WINDOWS TERMINÉ DANS $OutputDir ===" -ForegroundColor Cyan
