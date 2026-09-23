param(
  [string]$Version = "1.0.20260920",
  [string]$PayloadDir = "D:\nsis",
  [string]$ResultDir = "D:\nsis-result",
  [string]$ViVersion = ""
)

if (-not $ViVersion) {
  if ($Version -match '^(\d+)\.(\d+)\.(\d{8})$') {
    $ViVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3].Substring(0, 4)).$([int]$Matches[3].Substring(4))"
  } else {
    $ViVersion = "$Version.0"
  }
}

$makensis = Get-ChildItem 'C:\Program Files (x86)\NSIS\makensis.exe' | Select-Object -First 1
if (-not $makensis) {
  Write-Error 'NSIS makensis.exe not found'
  exit 1
}

New-Item -ItemType Directory -Force -Path $ResultDir | Out-Null
& $makensis.FullName "/DVERSION=$Version" "/DVI_VERSION=$ViVersion" "/DPayloadDir=$PayloadDir" "/DResultDir=$ResultDir" .\support\scripts\compile_windows_nsis.nsi
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Output "Generated Windows NSIS installer! (VERSION=$Version, VI_VERSION=$ViVersion)"
