# Nexus Synapse integration

Nexus applications use Synapse for their socket API. Add this directory to the
unit search path and use `blcksock`. TLS is supplied by the Nexus OpenSSL
package's `src` and `synapse` directories; include `obNXSynapseOpenSSL`.

`utNXSynapseResolver.pas` contains the FCL-derived resolver support used by the
Unix backend. It preserves forward/reverse IPv4/IPv6 and hosts-file resolution
and named service-to-port lookup. General network/protocol/service database
queries are not public APIs. Named service ports are returned in host order.
The optional libc declarations are private in `nxresolverlibc.inc`.

Build `tests/NXSynapseTests.nxproject` through Nexus nxbuild. The native runner
is Nexus `output/NXSynapseTests/<native-target>/NXSynapseTests`. Its 12 direct
nxtest cases use the host's standard localhost/services entries and bounded
IPv4/IPv6 loopback peers. Defining `NX_RESOLVER_LIBC` selects the retained libc
resolver for verification with the matching native socket/RTL build and adds
three direct resolver cases.

See [the consolidation record](../../FCL-NET-CONSOLIDATION.md) for proof,
consumer checks and limits. Upstream credits, extraction evidence and separate
Synapse/FCL/libc licensing are recorded in the
[central attribution record](https://github.com/nxrp-dev/nexus/blob/main/ATTRIBUTIONS.md#fcl-net).
Original headers, `COPYING.FPC` and the full LGPL text in `COPYING.txt` remain
with the extracted support. Synapse's original source retains its BSD notices.
