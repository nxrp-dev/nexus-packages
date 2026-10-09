# Nexus OpenSSL package

This package owns the dynamic OpenSSL binding (`src/openssl.pas`), certificate
and TLS object wrappers (`src/fpopenssl.pp`), and FCL socket adapter
(`src/opensslsockets.pp`). The original sources were imported from NexusFPC
commit af042760; the repair checkpoint builds on that import. Original license
notices remain in the inherited sources.

Add `src` to the compiler unit search path. The wrappers require matching
NexusFPC `fcl-net` units. Native OpenSSL libraries are loaded dynamically and
are not bundled here. The repaired certificate-generation path requires
OpenSSL 3. Existing legacy declarations remain; their presence does not certify
older OpenSSL or LibreSSL runtimes.

The repairs cover DNS and IP identity verification, the C SNI callback ABI and
owned routing data, generic PEM/DER private keys, PFX intermediate chains and
ownership, OpenSSL 3 symbol names, 64-bit context options and native BIO sizes,
X.509 decoding, SHA-256 certificate generation with DNS/IP SANs and generalized
validity dates, configuration failures, and socket readiness waits during TLS
I/O retries. SNI routes copy the domain lists; the caller must keep the referenced
`TSSLContext` objects alive while those routes are in use. OpenSSL contexts and
sessions must be released before explicitly unloading the native libraries.

Existing Nexus Synapse transports continue using their own bindings. This
package does not switch their provider. See [the binding review](BINDING-REVIEW.md)
for the comparison and remaining issues.

## Verification

On Windows x64, with LLVM tools on PATH and a matching built NexusFPC checkout:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test\Invoke-NXOpenSSLTests.ps1 `
  -NexusFPCRoot C:\gitdev\tools\nexus-fpc `
  -OpenSSLBin 'C:\Program Files\OpenSSL-Win64\bin'
```

The script generates disposable EC keys, a root/intermediate chain, three server
certificates, DER keys, and a PFX file under a unique temporary directory. It
builds and runs the NexusTest runner with range, overflow, I/O checks and heap
tracing. Tests use in-memory TLS and loopback sockets; no external service is
contacted. Build products, private keys and logs stay outside the repository.
The test password protects disposable fixtures only.

The ten tests cover EC keys and modern symbols, repeated PFX import and chain
contents, root-only verified PFX handshakes, matching/mismatching DNS and IPv4
identities, all three SNI routes after caller data changes, ALPN negotiation and
encrypted data, ALPN mismatch, generated DNS/IP certificates beyond 2049,
configuration rejection, and timeout semantics distinct from clean EOF.

Verified with NexusFPC 3.3.1 and OpenSSL 3.4.7 on Win64. Other operating systems
and architectures were not exercised. HeapTrc links successfully; the current
compiler reports two allocations originating in HeapTrc's own `Report` routine
at finalization. No application allocation appeared in those remaining traces.
This does not measure OpenSSL's native C heap.

The inherited `fpmake.pp` and namespace map describe the package. `Makefile`
builds the library-load example using the compiler selected through `FPC`.
