[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$FFIIncludeDir,
    [string]$PascalCompiler = 'fpc.exe',
    [string]$PascalRTLDir,
    [string]$CCompiler = 'gcc.exe',
    [Parameter(Mandatory = $true)][string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
$testDir = $PSScriptRoot
$sourceDir = (Resolve-Path -LiteralPath (Join-Path $testDir '..\src')).Path
$includeDir = (Resolve-Path -LiteralPath $FFIIncludeDir).Path
$runDir = Join-Path $OutputRoot ('NexusFFIABI-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDir | Out-Null
$pascalOptions = @()
if ($PascalRTLDir) {
    $rtlDir = (Resolve-Path -LiteralPath $PascalRTLDir).Path
    $pascalOptions = @('-n', "-Fu$rtlDir")
}

& $CCompiler "-I$includeDir" (Join-Path $testDir 'ffi_abi_probe.c') '-o' (Join-Path $runDir 'ffi_abi_probe_c.exe')
if ($LASTEXITCODE -ne 0) { throw 'C ABI probe compilation failed.' }

& $PascalCompiler @pascalOptions "-FU$runDir" (Join-Path $sourceDir 'ffi.pas')
if ($LASTEXITCODE -ne 0) { throw 'Pascal ffi unit compilation failed.' }

& $PascalCompiler @pascalOptions "-Fu$runDir" "-FU$runDir" "-FE$runDir" (Join-Path $testDir 'ffi_abi_probe.pas')
if ($LASTEXITCODE -ne 0) { throw 'Pascal ABI probe compilation failed.' }

$cResult = & (Join-Path $runDir 'ffi_abi_probe_c.exe')
if ($LASTEXITCODE -ne 0) { throw 'C ABI probe failed.' }
$pascalResult = & (Join-Path $runDir 'ffi_abi_probe.exe')
if ($LASTEXITCODE -ne 0) { throw 'Pascal ABI probe failed.' }

$difference = Compare-Object $cResult $pascalResult
if ($difference) {
    Write-Host 'Native libffi:'
    $cResult | Write-Host
    Write-Host 'Pascal binding:'
    $pascalResult | Write-Host
    throw 'Pascal libffi ABI does not match the native headers.'
}

Write-Host 'Pascal libffi ABI matches the native headers.'
Write-Host "Probe artifacts: $runDir"
