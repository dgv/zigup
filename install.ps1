#!/usr/bin/env pwsh
# Copyright 2018 the Deno authors. All rights reserved. MIT license.
# TODO(everyone): Keep this script simple and easily auditable.

$ErrorActionPreference = 'Stop'

$Version = if ($v) {
  $v
} elseif ($args.Length -eq 1) {
  $args.Get(0)
} else {
  "latest"
}

$Arch = [System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture.ToString().ToLower() 
$ZigupArch = if ($Arch -eq "x64") {
  "x86_64"
} else {
  "aarch64"
}

$ZigupInstall = $env:ZIGUP_INSTALL
$BinDir = if ($ZigupInstall) {
  "$ZigupInstall\bin"
} else {
  "$Home\.zigup\bin"
}

$ZigupZip = "$BinDir\zigup.zip"
$ZiguplExe = "$BinDir\zigup.exe"
$WintunDll = "$BinDir\wintun.dll"

# Zigup & GitHub require TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ZigupUri = "https://github.com/marler8997/zigup/releases/$Version/download/zigup-$ZigupArch-windows.zip"

if (!(Test-Path $BinDir)) {
  New-Item $BinDir -ItemType Directory | Out-Null
}

$prevProgressPreference = $ProgressPreference
try {
  # Invoke-WebRequest on older powershell versions has severe transfer
  # performance issues due to progress bar rendering - the screen updates
  # end up throttling the download itself. Disable progress on these older
  # versions.
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Output "Downloading zigup..."
    $ProgressPreference = "SilentlyContinue"
  }

  Invoke-WebRequest $ZigupUri -OutFile $ZigupZip -UseBasicParsing
} finally {
  $ProgressPreference = $prevProgressPreference
}

if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
  Expand-Archive $ZigupZip -Destination $BinDir -Force
} else {
  Remove-Item $ZigupExe -ErrorAction SilentlyContinue
  Remove-Item $WintunDll -ErrorAction SilentlyContinue
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($ZigupZip, $BinDir)
}

Remove-Item $ZigupZip

$User = [EnvironmentVariableTarget]::User
$Path = [Environment]::GetEnvironmentVariable('Path', $User)
if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) {
  [Environment]::SetEnvironmentVariable('Path', "$Path;$BinDir", $User)
  $Env:Path += ";$BinDir"
}

Write-Output "zigup was installed successfully to $ZigupExe"
Write-Output "Run 'zigup' to get started"
