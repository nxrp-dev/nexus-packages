# FCL Net review and Synapse assessment

Reviewed 2026-10-17 before implementation changes. Source: current NexusFPC
`packages/fcl-net`, based on `86b61cc9dd212d58802a77383f6264bd2de1f9a5`, after
retirement of the unused `fpSock`/`HTTPSvlt` async units. The untouched current
source and SHA-256 inventory are in Nexus `output/fcl-net-review/baseline` and
`baseline-hashes.json`. This review covers the seven remaining runtime units,
the platform resolver includes, namespace wrappers and retained tests.

## Consumers and technical value

A search of source/build files across Nexus, NexusFPC, Nexus Lab, Nexus Mobile
and Nexus Private, including ignored package repositories, found:

| Unit | Verified consumers outside this package | Assessment |
| --- | --- | --- |
| `netdb` | Synapse `ssfpc.inc`; Lab resolver demonstrations | Required by the current Unix Synapse backend for legacy hostname, service/protocol and reverse-address resolution. Its presence is an implementation dependency of Synapse, not a reason to expose another socket API. |
| `sslbase` | `fpopenssl`, Nexus `obNXSynapseOpenSSL`, OpenSSL tests | Required certificate/key/configuration model for the shared OpenSSL wrappers and Nexus Synapse TLS adapter. |
| `ssockets` | `opensslsockets`, OpenSSL tests, Lab socket demonstrations | An alternative stream/socket/server API. No production Nexus application directly imports it. Its active test use must be converted before removal. |
| `sslsockets` | `opensslsockets`, Lab TLS demonstration | Alternative FCL TLS socket handler. Production Nexus TLS uses its Synapse adapter. |
| `resolve` | `ssockets`; Lab component resolver demonstrations | Component wrappers around resolver/URI functions; no direct production Nexus consumer. |
| `fpsockets` | `ssockets`; three retained standalone socket test programs | Alternative record/generic socket API; no direct production Nexus consumer. |
| `cnetdb` | optional libc branch of `netdb`; Lab C resolver demonstration | Platform resolver bindings, rather than an independent networking stack. |

Production Synapse consumers include BotHost file exchange, XMPP, the LSP TCP
transport and torrent peer connections. They inherit the Unix `netdb` dependency.

Synapse already supplies TCP/UDP, IPv4/IPv6, readiness checks, grouped read
readiness, TLS integration and DNS record queries (`dnssend`). Maintaining FCL
counterparts for developer familiarity adds a second public feature surface.
The concrete extra capability found in FCL Net is Unix-domain sockets: its
`fpsockets`/`ssockets` APIs support AF_UNIX, while the current Synapse block-socket
family exposes only IPv4/IPv6. No production Nexus consumer of that capability
was found. FCL's TStream facade is an API shape, not an independently required
capability.

Recommendation: make Synapse the application networking API. Preserve required
resolver/TLS support until its consumers are deliberately migrated; do not remove
the whole package as unused. Retire duplicate socket APIs after converting their
useful tests and demonstrations. Unix-domain support can be added at the single
networking boundary if a concrete Nexus requirement appears.

## Findings recorded before implementation

| ID | Location | Actual defect and regression |
| --- | --- | --- |
| N01 | `resolve.pas`, TResolver.Destroy | Omits inherited TComponent destruction, retaining the resolver in its owner's component list and leaking owned components. Verify owner detachment and child destruction. |
| N02 | `fpsockets.pas`, CreateAddr Unix branch | Sets sun_family before zeroing the record, erasing AF_UNIX. Verify Unix socket address construction directly. |
| N03 | `fpsockets.pas`, ReadAddr Unix branch | Tests AF_INET6 again instead of AF_UNIX; the unreachable pathname loop also never increments its index. Verify Unix endpoint decoding with a nonempty path. |
| N04 | `ssockets.pas`, TSocketStream.Select | Filters write/exception results using the read descriptor set and the already modified read array. Verify write-only readiness and independent result arrays. |
| N05 | `ssockets.pas`, TSocketStream.Select | Treats descriptor zero as an empty input and passes negative timeouts as invalid timeval values. Verify descriptor-zero readiness and a negative timeout on a ready socket. |
| N06 | `sslbase.pas`, TX509Certificate.GetVersion | First default read returns zero, then changes the field to one. Verify stable default reads and explicit versions. |
| N07 | `netdb.pas`, DNSRRGetText UDP/TCP | Treats an empty TXT character string as failure and bounds each string against the full payload instead of its record length. Verify empty strings and rejection of strings that cross the declared RDATA boundary. |

The owner explicitly chose to relocate the remaining package intact and document
the consolidation recommendation. No duplicate APIs are retired in this pass.

## Additional findings from retained live socket tests

Recorded before these implementation changes: the original standalone UDP test
fails its first case by timeout; the TCP test fails accepting its first client
with an unsupported/random address family. Inspection ties both to the same
record-layout error, rather than invalid test expectations.

| ID | Location | Actual defect and regression |
| --- | --- | --- |
| N08 | `fpsockets.pas`, SendTo/ReceiveFrom/AcceptConnection/AcceptNonBlocking/LocalEndpoint/RemoteEndpoint | Passes `@addr`, the whole tagged TAddressUnion, as a native sockaddr. Its discriminant precedes the actual address fields, so sends expose the wrong address family and receives overwrite the tag instead of the address payload. AcceptConnection also leaves its input address length uninitialized. Verify local UDP roundtrip, TCP accept and endpoint lookup. Use the record's existing GetAddrAndSize method at the native boundary. |
| N09 | `fpsockets.pas`, TAddressUnion.GetAddrSize | Reports IPv4 structure size for stIPDualStack even though its socket is IPv6. Verify the native address size for a dual-stack record. |

## Corrections and regression proof

All nine findings were reproduced against the untouched snapshot. No retained
suite failure was dismissed as upstream or removed as an invalid test.

| Finding | Regression cases | Correction |
| --- | --- | --- |
| N01 | `resolver-ownership` | Call inherited component destruction after releasing resolver data. |
| N02 | `unix-address` | Initialize the Unix address record before setting AF_UNIX. |
| N03 | `unix-endpoint` | Select the Unix branch by AF_UNIX and advance the pathname cursor. |
| N04 | `select-write` | Filter each output array with its own descriptor set and original input array. |
| N05 | `select-infinite`, `select-zero` | Track an empty set with -1 and use a nil timeout pointer for indefinite waits. |
| N06 | `certificate-version` | Return the documented default on the first and subsequent reads without mutating the field. |
| N07 | six `txt-*` cases | Decode length-prefixed strings, including empty segments, within the record's declared RDATA boundary. |
| N08 | `udp-loopback`, `tcp-loopback`, `tcp-nonblocking` | Use the address field and initialized native length for send/receive/accept/endpoint calls. |
| N09 | `dual-stack-size` | Size dual-stack address storage as IPv6. |

The native address helper now uses `TSockLen` for its length/result rather than
`cint`, so pointer arguments match the platform socket declarations without
casts. All package call sites were updated; no outside callers of this helper
were found. No new threads, socket abstraction or compatibility bridge is added.

The TXT cases follow the character-string and TXT formats in
[RFC 1035 sections 3.3 and 3.3.14](https://www.rfc-editor.org/rfc/rfc1035#section-3.3.14).
The baseline rejects valid empty/segmented strings and accepts strings crossing
the declared record boundary; the corrected implementations handle both UDP and
TCP payload types consistently.

## Final verification

Native compiler: installed NexusFPC 3.3.1, x86_64-linux, build
`778927a6beede09df345f5e9ee5e95f500b4f838-work-95622f1b76`, using Nexus nxbuild.

| Check | Result |
| --- | --- |
| Untouched source with current direct nxtest regressions | 110 retained tests pass; all 17 regression cases fail, proving the nine findings. |
| Corrected relocated source | **127 passed; 0 failed; 0 errors; 0 skipped.** |
| Original standalone address test | All 4 cases pass. |
| Original standalone UDP test | All 10 cases pass, including IPv4, IPv6, dual-stack, fragmentation and nonblocking I/O. |
| Original standalone TCP test | All 12 cases pass, including IPv4, IPv6, dual-stack, closure, refused connections and fragmentation. |
| FCLNet.nxpackage | All seven runtime units build on native Linux. |
| Synapse runtime smoke | localhost resolution, Nexus TLS adapter selection, OpenSSL 3 context creation and SHA-256 reference digest pass. |
| Consumer unit builds | XMPP transport, torrent peer connection, LSP TCP transport, BotHost file exchange, OpenSSL test unit and LS search-path unit build. |
| Nexus Lab XMPP project | Existing native project builds with the relocated source path. |
| Descriptor and both package catalogs | Validate with the nxpackage dialect. |
| Relocation integrity | All 25 original files preserved; all namespace wrappers, platform includes and original behavioral test bodies remain byte-identical. Original package directory removed. |

The initial retained UDP timeout and TCP accept failure were implementation bugs,
not invalid tests. Their sources remain unchanged and their complete suites now
pass. Loopback tests require normal local socket binding; this environment's
restricted sandbox denies binding, so the bounded live checks ran outside it.

Both catalogs register `NXRP.Network.FCLNet`. Active source paths in the Lab XMPP
recipe and LS search-path defaults point to the destination. NexusFPC's package
requirements and the OpenSSL package documentation identify the new owner.
The older path strings in Lab URI parser test data are URI examples, not build
inputs, and were preserved. No compiler or RTL bootstrap input was relocated.

## Consolidation recommendation

Use Synapse as the public Nexus networking API. Developer familiarity with FCL
is not a technical reason to maintain parallel feature surfaces.

A later approved consolidation can first preserve or relocate the resolver
support needed by Synapse and the certificate types needed by OpenSSL, then
convert the FCL-specific OpenSSL tests and relevant Lab demonstrations to
Synapse. After those consumers move, the duplicate `opensslsockets`,
`sslsockets`, `ssockets`, `resolve` and `fpsockets` layers can be retired.
Do not replace the current resolver dependency with another DNS client merely
to rename the dependency: preserve the actual hostname/service/reverse-lookup
behavior required by the Synapse backend. Unix-domain socket support has no
verified production consumer and need not justify a second public socket API.

## Unverified limits

Windows, other Unix targets and dotted-unit builds were not executed. The
Windows branch continues to select its original resolver include; this report
does not claim target validation from source inspection. Delphi is unsupported.
The OpenSSL test unit compiles and the native Synapse/TLS/crypto smoke passes;
the separate complete TLS handshake/certificate fixture suite was not rerun.
Production transport units were compiled, rather than launching BotHost, LSP,
torrent or an external XMPP service. No performance or whole-compiler rebuild
claim is made.

## Evidence

Generated proof/build logs and the untouched source stay under Nexus
`output/fcl-net-review`; final native nxtest output is under
`output/fcl-net-tests/x86_64-linux`. Main evidence files are
`baseline-nxtest-results.log`, `final-results.log`, `package-build.log`,
`lab-xmpp-build.log`, `consumers/results.json`, `consumers/socket-*-results.log`
and `validation-results.json`. No source/evidence archive is added to Git.
Third-party provenance and notices belong to the central
[attribution record](../../../../ATTRIBUTIONS.md#fcl-net).

### Original current-tree SHA-256 inventory

| Original relative path | SHA-256 |
| --- | --- |
| `README.txt` | `259443697de0228b268334c11f7835c213d57853ff9378158ff3d8ff5b11f378` |
| `namespaced/System.Net.Cnetdb.pas` | `4948c190722b5b30c5debff5bb0b04c7df8736be034790294f94d3b482045d62` |
| `namespaced/System.Net.FPSockets.pas` | `a2445123af06a909ca54d9d7f26998ccbd6cdc8cb604e332737973f5b172f8de` |
| `namespaced/System.Net.Netdb.pas` | `7e2b88dd01527c8fd16a7239ff0698bb9725e2933f40268572339bf0333ea19c` |
| `namespaced/System.Net.Resolve.pas` | `9b9d7071c312c435d9e2e04e66812943a2ddb3bfec7b279817399f4d83317811` |
| `namespaced/System.Net.Sslbase.pas` | `b49943be5c5368a181e3652bc9af51e0bb28f71974770feb7eab70e7085c29da` |
| `namespaced/System.Net.Sslsockets.pas` | `763fcfdaef1f99e9c2f74bea7656b22152ad7f4974cad5c11a55c059ae74a63c` |
| `namespaced/System.Net.Ssockets.pas` | `903a0383d5914040b31bde3708a4664ac4e58ebeb1cf28550afbda615d6e4433` |
| `namespaces.lst` | `dd137938c4eab512b5e5ccd14828ea9c8ebd7c58036f647506fd2f6a0cd327b5` |
| `src/cnetdb.pas` | `64b9ea6841fdc1483eca987d4ccba99c196fc9bd6cc6efbc070e3310758c6167` |
| `src/fpsockets.pas` | `3cf3b1c1f1a85492ed128339eb71cf4875fddba406d7305cf5789cf1c15868a3` |
| `src/netdb.pas` | `1db66a63cd30ee4dced51d475a7957c33fd64b0a08594f196523aaee9a2d2b74` |
| `src/resolve.pas` | `358ea63505925a598aa16e263ca0c5d4423546e47da1e0874a5b9c79c1e7e3af` |
| `src/sslbase.pas` | `3a47ba3bea0b8303691be08240a9adcc862beddfee6d7575d479f8129c4c068e` |
| `src/sslsockets.pas` | `83b1b2ea377d289abcdd276c84edf0bf54dada1b54088dc8418539329a15aed8` |
| `src/ssockets.pas` | `e7019f4c37ea8ae28496a706fdabab09e33e284e2d95e7a270487905bf7e99b8` |
| `src/unix/resolve.inc` | `31b120bd34f9d8c0f264927f92d63e361dff4cb347e6997eb2de23538c788f6e` |
| `src/win/resolve.inc` | `f5b24c50dc10f776e6aa263bc85ce70858b72ca512413cbd0523c6f281768bff` |
| `tests/FCLNetTests.lpr` | `f77b358ac781f67742c1a5f864e9787c915558666c52a64779dd78848c85f566` |
| `tests/FCLNetTests.nxproject` | `3f26ba57f9678643ccf97e6c7cf2442d28eed7986f35fe5b72319d5f16fb9b78` |
| `tests/NXTEST.md` | `4e7db65a7ce88cbea660ffbe406682014d106be83c4cd237d4b36ae52b7e0907` |
| `tests/netdbtest.pas` | `bee5a4f82a7eb8bccbeef8c06c619c07cd18ab39cd4cfa9d5def241cb8f0a51f` |
| `tests/tfpsock1.pas` | `3f1a5235b5ac537796a940b36231a2e964f1ef2fda2d65cc31f883194432a025` |
| `tests/tfpsock2.pas` | `8d98a781d253596fda255abdc05e5fb9e8d7235f3030e70479c144dc78826ece` |
| `tests/tfpsock3.pas` | `a417bdcacdb6e23cd1d488eb0d6875e2e701eddfa125f2605b3ff5f679080895` |
