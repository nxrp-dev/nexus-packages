# FCL Net consolidation

Authorized by the owner on 2026-10-17: remove FCL Net, move the resolver support
Synapse actually uses into Synapse, and move the shared certificate model into
OpenSSL. Do not retain unused network/protocol/service database query APIs.

## Review before implementation

The required Unix resolver calls are IPv4 hosts-file lookup, A/AAAA DNS lookup,
reverse IPv4/IPv6 lookup and named service-to-port resolution. Keep their
implementation with Synapse. Network database queries, reverse service lookup,
public protocol catalogs, unused DNS record decoders and component resolvers
have no production consumers and will be removed.

The shared TLS model's live definitions are TSSLType, TSSLData, TCertAndKey and
TX509Certificate. TCertificateData belongs only to the retired FCL handler and
will be removed. OpenSSL's retained tests use FCL socket classes for listeners,
configuration and read deadlines; convert that behavioral coverage to Synapse
before deleting the alternative socket/TLS stack.

The current Unix ResolvePort converts the FCL service entry's already host-order
port with ntohs. Prove the named-port result before correcting the extraction.
Retain the proven default-certificate-version regression in OpenSSL.

The earlier package review and its source hashes are in Git history. The current
untouched input and hashes are under ignored output/fcl-net-removal/baseline.
Original notices and licenses move with retained material; attribution remains
in the root central record. No tracked source or evidence archive is created.

## Results

FCL Net is removed, including its descriptor, build recipe, catalog entries,
namespace wrappers, alternative socket/TLS/component layers and old test
runners. There are no compatibility units or aliases. The current extraction
input is Packages commit `cd5d3127db14b6acf33a7c83f0c3dcb3d328a2e5`.

The resolver unit exports only six operations used by `ssfpc.inc`: hosts-file
address lookup, forward IPv4/IPv6 resolution, reverse IPv4/IPv6 resolution and
service-name-to-port resolution. The protocol-number and service-file helpers
needed for the last operation are private. Network-name queries, reverse
service lookup, protocol catalogs and returned alias records are not exported.
The existing Pascal A/AAAA/PTR resolver algorithms remain; unused DNS record
APIs and TCP packet decoders were removed. The private libc subset retains the
Android/FPC_USE_LIBC branch without importing the old general-purpose cnetdb.

`tpNXOpenSSLTypes` owns the enum and certificate/key record;
`obNXOpenSSLCertificates` owns the live classes. The shared wrapper and Synapse
adapter import those definitions directly. TCertificateData and the FCL socket
adapter are gone. All OpenSSL test listeners and peers now use Synapse. The
FCL stream-handler read-timeout case was removed; the existing Synapse
partial-record deadline test already covers the required timeout/session
behavior. Configuration rejection is checked at the wrapper/adapter boundaries.
The stable certificate-version regression moved into the OpenSSL suite.

Old FCL-only packet-decoder/component/socket tests and runners were removed
with their implementations. Focused Synapse nxtest cases cover numeric/named
ports, hosts-file lookup, literals/localhost and IPv4/IPv6 TCP and UDP roundtrips.
The old netdb test harness was not copied into Synapse merely to retain APIs
that applications do not use.

Useful Lab TCP/resolver/TLS examples now use Synapse, with one native build
recipe. Database-only, duplicate and Unix-domain demonstrations were removed.
The Lab XMPP project, both catalogs, LS defaults and tracked NexusCode path
settings no longer point to the removed package. Original notices and licenses
move with retained material. Central provenance remains in root ATTRIBUTIONS.md.

## Regression proof and verification

Native environment: NexusFPC 3.3.1 x86_64-linux identity
`778927a6beede09df345f5e9ee5e95f500b4f838-work-95622f1b76`, Nexus nxbuild and
OpenSSL 3.0.13. Range, overflow and I/O checks are enabled in the test recipes.

| Check | Result |
| --- | --- |
| Untouched Synapse backend with the new behavioral tests | 10 pass; named TCP and UDP service-port cases fail. |
| Extracted resolver with the host-order service-port fix | **12 pass; 0 failures/errors/skips.** |
| Retained libc resolver branch on the native socket/RTL build | **15 pass**, including direct forward/reverse lookup, unpadded C strings and empty output arrays. |
| OpenSSL suite using Synapse sockets | **22 pass**, including the moved default-version regression. |
| XMPP transport nxtest | **5 pass.** |
| Complete deterministic XMPP suite | Pass. |
| OpenSSL.nxpackage | Native package and Nexus Synapse adapter build. |
| Consumer units | BotHost file exchange/OpenAI provider, torrent connection, LSP TCP transport and LS search paths build from fresh output directories. |
| Lab examples | TCP client/server, resolver and TLS verification examples build; IPv4/IPv6 TCP echo, localhost resolution and named-port output pass. |
| Lab XMPP console | Native project builds without FCL Net. |
| OpenSSL descriptor and both catalogs | NexusScript dialect validation passes. |

The initial optional-libc test incorrectly set FPC_USE_LIBC globally against a
prebuilt RTL using the native syscall backend. Tracing showed a real successful
nonblocking IPv6 connect initiation while the mixed build reported an unrelated
errno. The corrected check selects only the retained resolver branch with
NX_RESOLVER_LIBC and keeps the matching native socket/RTL implementation; all
15 cases pass. This is a test-configuration correction, not a product fix.
The original IPv6 string comparison was also corrected to compare addresses,
since equivalent textual spellings are valid.

Before/after logs and verification recipes are under ignored Nexus
`output/fcl-net-removal`. Local peer tests ran with normal loopback binding;
there are no external-service test results in this pass.

## Limits

Windows, Android and other Unix targets were not executed. The libc branch was
exercised on native Linux, not with a complete FPC_USE_LIBC-built RTL. The
remaining Pascal DNS wire-query path retains its existing algorithms, but no
controlled DNS-server transaction or external DNS service was exercised in
this pass. No full compiler/RTL rebuild, external XMPP service, torrent swarm,
or production BotHost session was launched.

