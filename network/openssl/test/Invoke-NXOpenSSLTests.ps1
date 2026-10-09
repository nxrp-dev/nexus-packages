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
$compiler = Join-Path $NexusFPCRoot 'compiler\ppcx64.exe'
$openssl = Join-Path $OpenSSLBin 'openssl.exe'
foreach ($required in @($compiler, $openssl,
    (Join-Path $OpenSSLBin 'libssl-3-x64.dll'),
    (Join-Path $OpenSSLBin 'libcrypto-3-x64.dll'))) {
  if (!(Test-Path -LiteralPath $required -PathType Leaf)) {
    throw "Required tool or runtime is missing: $required"
  }
}
$runRoot = Join-Path ([IO.Path]::GetTempPath()) ('nx-openssl-tests-' + [guid]::NewGuid().ToString('N'))
$fixtures = Join-Path $runRoot 'fixtures'
$units = Join-Path $runRoot 'units'
New-Item -ItemType Directory -Path $fixtures, $units | Out-Null
$nativeLog = Join-Path $runRoot 'fixtures.log'

function Invoke-OpenSSL {
  param([string[]]$NativeArguments)
  & $openssl @NativeArguments >> $nativeLog 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "OpenSSL fixture generation failed; see $nativeLog"
  }
}

# Generate disposable keys and certificates; no private keys enter the repository.
$config = Join-Path $fixtures 'openssl.cnf'
Set-Content -LiteralPath $config -Encoding ASCII -Value "[req]`ndistinguished_name=dn`n[dn]"
$caExtension = Join-Path $fixtures 'ca.ext'
Set-Content -LiteralPath $caExtension -Encoding ASCII -Value "basicConstraints=critical,CA:TRUE,pathlen:0`nkeyUsage=critical,keyCertSign,cRLSign"
$rootKey = Join-Path $fixtures 'root.key'
$rootCert = Join-Path $fixtures 'root.pem'
Invoke-OpenSSL -NativeArguments @('req', '-new', '-x509', '-newkey', 'ec', '-pkeyopt', 'ec_paramgen_curve:P-256', '-noenc', '-sha256', '-days', '3650', '-config', $config, '-subj', '/CN=Nexus OpenSSL Test Root', '-addext', 'basicConstraints=critical,CA:TRUE,pathlen:1', '-addext', 'keyUsage=critical,keyCertSign,cRLSign', '-keyout', $rootKey, '-out', $rootCert)
$intermediateKey = Join-Path $fixtures 'intermediate.key'
$intermediateRequest = Join-Path $fixtures 'intermediate.csr'
$intermediateCert = Join-Path $fixtures 'intermediate.pem'
Invoke-OpenSSL -NativeArguments @('req', '-new', '-newkey', 'ec', '-pkeyopt', 'ec_paramgen_curve:P-256', '-noenc', '-config', $config, '-subj', '/CN=Nexus OpenSSL Test Intermediate', '-keyout', $intermediateKey, '-out', $intermediateRequest)
Invoke-OpenSSL -NativeArguments @('x509', '-req', '-in', $intermediateRequest, '-CA', $rootCert, '-CAkey', $rootKey, '-set_serial', '2', '-sha256', '-days', '3650', '-extfile', $caExtension, '-out', $intermediateCert)
$serial = 10
foreach ($hostName in @('first', 'second', 'third')) {
  $key = Join-Path $fixtures ($hostName + '.key')
  $request = Join-Path $fixtures ($hostName + '.csr')
  $cert = Join-Path $fixtures ($hostName + '.pem')
  $extension = Join-Path $fixtures ($hostName + '.ext')
  Set-Content -LiteralPath $extension -Encoding ASCII -Value "basicConstraints=critical,CA:FALSE`nkeyUsage=critical,digitalSignature`nextendedKeyUsage=serverAuth`nsubjectAltName=DNS:$hostName.test,DNS:localhost,IP:127.0.0.1"
  Invoke-OpenSSL -NativeArguments @('req', '-new', '-newkey', 'ec', '-pkeyopt', 'ec_paramgen_curve:P-256', '-noenc', '-config', $config, '-subj', "/CN=$hostName.test", '-keyout', $key, '-out', $request)
  Invoke-OpenSSL -NativeArguments @('x509', '-req', '-in', $request, '-CA', $intermediateCert, '-CAkey', $intermediateKey, '-set_serial', [string]$serial, '-sha256', '-days', '3650', '-extfile', $extension, '-out', $cert)
  $serial++
  Set-Content -LiteralPath (Join-Path $fixtures ($hostName + '-chain.pem')) -Encoding ASCII -Value ((Get-Content -LiteralPath $cert -Raw) + (Get-Content -LiteralPath $intermediateCert -Raw))
  Invoke-OpenSSL -NativeArguments @('pkey', '-in', $key, '-outform', 'DER', '-out', (Join-Path $fixtures ($hostName + '.der')))
}
Invoke-OpenSSL -NativeArguments @('pkcs12', '-export', '-in', (Join-Path $fixtures 'first.pem'), '-inkey', (Join-Path $fixtures 'first.key'), '-certfile', $intermediateCert, '-passout', 'pass:nexus-test', '-out', (Join-Path $fixtures 'first.pfx'))

$compilerArguments = @('-n', '-B', '-Mobjfpc', '-Sh', '-O1', '-gl', '-gh', '-Cr', '-Co', '-Ci', '-vewn',
  ('-Fu' + (Join-Path $NexusFPCRoot 'rtl\units\x86_64-win64')))
foreach ($directory in (Get-ChildItem -Directory (Join-Path $NexusFPCRoot 'packages\*\units\x86_64-win64'))) {
  $compilerArguments += '-Fu' + $directory.FullName
}
$compilerArguments += @(
  ('-Fu' + (Join-Path $packageRoot 'src')),
  ('-Fu' + (Join-Path $packagePool 'nxtest\src')),
  ('-FU' + $units), ('-FE' + $runRoot),
  (Join-Path $PSScriptRoot 'NXOpenSSLTests.lpr'))
$buildLog = Join-Path $runRoot 'build.log'
& $compiler @compilerArguments > $buildLog 2>&1
if ($LASTEXITCODE -ne 0) { throw "OpenSSL test compilation failed; see $buildLog" }
$resultsLog = Join-Path $runRoot 'results.log'
$heapLog = Join-Path $runRoot 'heaptrc.log'
& (Join-Path $runRoot 'NXOpenSSLTests.exe') $fixtures $OpenSSLBin > $resultsLog 2> $heapLog
$testExit = $LASTEXITCODE
Get-Content -LiteralPath $resultsLog
if ((Get-Item -LiteralPath $heapLog).Length -gt 0) { Write-Output "Heap trace report: $heapLog" }
Write-Output "Verification files: $runRoot"
exit $testExit
