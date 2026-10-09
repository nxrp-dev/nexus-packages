# Copyright (c) 2026 Kevin Collins.
# SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
param(
  [string]$NexusFPCRoot = 'C:\gitdev\tools\nexus-fpc',
  [string]$OpenSSLBin = 'C:\Program Files\OpenSSL-Win64\bin'
)
$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest
$packageRoot = Split-Path -Parent $PSScriptRoot
$packagePool = Split-Path -Parent (Split-Path -Parent $packageRoot)
$nexusRoot = Split-Path -Parent (Split-Path -Parent $packagePool)
$compiler = Join-Path $NexusFPCRoot 'compiler\ppcx64.exe'
if (!(Test-Path -LiteralPath $compiler -PathType Leaf)) { throw "Compiler missing: $compiler" }
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('nx-xmpp-tests-' + [guid]::NewGuid().ToString('N'))
$units = Join-Path $runRoot 'units'
New-Item -ItemType Directory -Path $units | Out-Null
$compilerArguments = @('-n', '-B', '-Mobjfpc', '-Sh', '-O1', '-gl', '-Cr', '-Co', '-Ci', '-vewn',
  ('-Fu' + (Join-Path $NexusFPCRoot 'rtl\units\x86_64-win64')))
foreach ($directory in (Get-ChildItem -Directory (Join-Path $NexusFPCRoot 'packages\*\units\x86_64-win64'))) {
  $compilerArguments += '-Fu' + $directory.FullName
}
foreach ($source in @('network\xmpp\src', 'network\external\synapse', 'network\openssl\src', 'network\openssl\synapse')) {
  $compilerArguments += '-Fu' + (Join-Path $packagePool $source)
}
$compilerArguments += @(('-FU' + $units), ('-FE' + $runRoot),
  (Join-Path $PSScriptRoot 'NexusNetXMPPTests.lpr'))
$env:PATH = $OpenSSLBin + ';' + $env:PATH
& $compiler @compilerArguments > (Join-Path $runRoot 'build.log') 2>&1
if ($LASTEXITCODE -ne 0) { throw "XMPP compilation failed; see $runRoot\build.log" }
Push-Location $nexusRoot
try {
  # Only synthetic loopback fixtures; live-server targets are separate.
  & (Join-Path $runRoot 'NexusNetXMPPTests.exe') > (Join-Path $runRoot 'results.log') 2>&1
  $testExit = $LASTEXITCODE
  Get-Content -LiteralPath (Join-Path $runRoot 'results.log')
} finally { Pop-Location }
Write-Output "Verification files: $runRoot"
exit $testExit
