# Nexus OpenSSL package

This package owns the dynamic OpenSSL binding (`src/openssl.pas`), certificate
and TLS object wrappers (`src/fpopenssl.pp`), shared cryptography helpers
(`src/obNXOpenSSLCrypto.pas`), certificate definitions in
`src/tpNXOpenSSLTypes.pas` and `src/obNXOpenSSLCertificates.pas`, and the
Nexus-owned Synapse adapter (`synapse/obNXSynapseOpenSSL.pas`). Upstream
origins, import evidence, authors, and separate native-library/binding license
indicators are maintained in the
[central attribution record](https://github.com/nxrp-dev/nexus/blob/main/ATTRIBUTIONS.md#openssl-and-fpc-bindings).
Original notices remain in the inherited sources.

Add `src` to the compiler unit search path. Certificate data and generator
classes are owned here; FCL Net is no longer required. `OpenSSL.nxproject` builds
the wrappers and Nexus Synapse adapter with the configured native NexusFPC.
Native OpenSSL libraries are loaded dynamically and
are not bundled here. The runtime must be OpenSSL 3 and supply the required
TLS and cryptography
exports. Each candidate library pair is validated before loading is published;
an incomplete load is released and can be retried. Historical declarations
remain, but older OpenSSL and LibreSSL runtimes are rejected.

The repairs cover DNS and IP identity verification, the C SNI callback ABI and
owned routing data, generic PEM/DER private keys, PFX intermediate chains and
ownership, OpenSSL 3 symbol names, 64-bit context options and native BIO sizes,
X.509 decoding, SHA-256 certificate generation with DNS/IP SANs and generalized
validity dates, configuration failures, and socket readiness waits during TLS
I/O retries. SNI routes copy the domain lists; the caller must keep the referenced
`TSSLContext` objects alive while those routes are in use. OpenSSL contexts and
sessions must be released before explicitly unloading the native libraries.

XMPP and BotHost now use this binding and runtime loader for both TLS and
cryptography. XMPP's independent loader has been removed. Synapse's vendored
OpenSSL adapters and bindings remain untouched and are no longer selected by
these consumers. See [the binding review](BINDING-REVIEW.md).

For Synapse integration, add this package's `src` and `synapse` folders and
`network/external/synapse` to the unit search path. Include `obNXSynapseOpenSSL`
to register `TNXSynapseOpenSSL`, which descends directly from `TCustomSSL`.
Keep other TLS-provider registration units out of that application's uses graph.
The adapter owns its context and session; Synapse owns the socket. `LT_All`
negotiates TLS 1.2 or later; explicit `LT_TLSv1_2` and `LT_TLSv1_3` select just
that version. Older protocols are rejected. Verification uses `SNIHost` as the
reference identity, or the connected peer IP when no name is provided; SNI is
sent for DNS names only. HTTP and XMPP callers already provide their service name.

ALPN is configured through `Socket.SSL.ALPNProtocols`, a comma-separated protocol
list in preference order. The Nexus provider installs it before the client or
server handshake. Read `Socket.SSL.SelectedALPNProtocol` afterward; it is empty
when ALPN was not negotiated, before a successful handshake, or after shutdown.
`Assign` copies the configured offer, never the negotiated session result. An
empty configuration disables ALPN; an empty-token-only list or a protocol ID
longer than 255 bytes fails TLS setup. The application offers only protocols it
implements and decides whether an absent selection is acceptable.

XMPP direct TLS offers `xmpp-client`; STARTTLS clears the offer, including when
reusing a transport that previously used direct TLS. HTTP consumers keep their
existing empty default. Negotiating `h2` does not itself implement HTTP/2.

Handshake retries share the socket's `ConnectionTimeout` deadline. Send retries
share `NonblockSendTimeout`; read retries share the adapter's `ReceiveTimeout`
(default -1, unbounded). Set that property to the caller's receive timeout,
including when calling Synapse's timed receive APIs: their initial readiness
wait alone cannot bound a partial TLS record. BotHost and XMPP do this explicitly.
Each operation restores the previous socket mode, and hard shutdown accepts a
sent close_notify without waiting for the peer. Failure to load/configure TLS
fails the operation; the adapter never substitutes a plaintext provider.

`TNXOpenSSLCrypto` provides raw binary SHA-1/SHA-256, streaming SHA-256,
HMAC-SHA-256, PBKDF2-HMAC-SHA-256, secure random bytes, and constant-time comparison
of equal-length inputs. SHA-1 remains for the XEP-0115 protocol digest. Helpers
use the shared binding and caller-owned output buffers; there is no second loader.
Shared crypto errors use `ESSL`; protocol validation errors remain owned by XMPP.

## FCL Net removal — 2026-10-17

The FCL socket handler was removed. The live `TSSLType` and `TCertAndKey`
definitions live in `tpNXOpenSSLTypes`; `TSSLData` and `TX509Certificate` live in
`obNXOpenSSLCertificates`. Consumers import those owners directly. The unused
FCL-handler certificate container was removed. Original licenses and source
headers remain with the extracted definitions.

The current 22-case OpenSSL suite uses Synapse listeners and peers throughout.
Configuration rejection remains covered at the shared context and Synapse
boundaries. Synapse tests retain the partial-record read deadline and distinction
between timeout and session closure; the obsolete FCL stream-handler timeout
case was removed. The stable certificate default-version regression now runs
here directly. See [consolidation review and results](../FCL-NET-CONSOLIDATION.md).

## Native ALPN verification — 2026-10-17

From the Nexus root on Linux:

```sh
bash packages/nexus-packages/network/openssl/test/Generate-NXOpenSSLFixtures.sh output/synapse-alpn/fixtures
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/network/openssl/test/NXOpenSSLTests.nxproject
output/NXOpenSSLTests/x86_64-linux/NXOpenSSLTests output/synapse-alpn/fixtures /usr/lib/x86_64-linux-gnu
```

The final argument is the directory containing the native OpenSSL 3 libraries;
select the matching directory for the host. Fixtures contain disposable test
keys. The native recipe uses the configured NexusFPC compiler and matching RTL;
it compiles the `.pp` wrapper units explicitly before the test runner.

On x86_64 Linux, NexusFPC 3.3.1 identity
`778927a6beede09df345f5e9ee5e95f500b4f838-work-95622f1b76` with OpenSSL 3.0.13:
**22 nxtest cases passed** (14 retained and 8 new Synapse adapter cases). The
new cases cover matching protocols, server preference, case-sensitive matching,
no overlap, either peer omitting ALPN, disabled negotiation, invalid settings,
configuration copying and session cleanup. With only the public API added and
the adapter not yet wired, five adapter cases failed; all passed after wiring.
The five XMPP transport nxtest cases and retained complete XMPP suite also pass.
BotHost's file-exchange and OpenAI-provider consumer units compile against the
updated Synapse interface and Nexus adapter with the same native toolchain.
Generated logs stay under Nexus `output/synapse-alpn`. Windows was not rerun for
this addition; the earlier Windows results below are historical.

## Earlier Windows verification

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

The fourteen tests cover EC keys and modern symbols, repeated PFX import and chain
contents, root-only verified PFX handshakes, matching/mismatching DNS and IPv4
identities, all three SNI routes after caller data changes, ALPN negotiation and
encrypted data, ALPN mismatch, generated DNS/IP certificates beyond 2049,
configuration rejection, and timeout semantics distinct from clean EOF.
Additional checks cover crypto known-answer vectors and a stream crossing 64 KiB,
loader rejection/recovery, and the owned Synapse adapter with EC PEM/DER keys,
PFX intermediate transmission, verified DNS/IP identities, encrypted data,
TLS 1.3, silent-peer handshake deadlines, partial-record read deadlines, socket
mode restoration, and one-way shutdown.

Verified with NexusFPC 3.3.1 and OpenSSL 3.4.7 on Win64. Other operating systems
and architectures were not exercised. HeapTrc links successfully; the current
compiler reports two allocations originating in HeapTrc's own `Report` routine
at finalization. No application allocation appeared in those remaining traces.
This does not measure OpenSSL's native C heap.

The inherited `fpmake.pp` and namespace map describe the core package. The
Synapse adapter is an optional source integration and is not added as a core
FCL package dependency. `Makefile`
builds the library-load example using the compiler selected through `FPC`.
