# NexusNet XMPP Test Record

This is the retained verification record for the deterministic Win64
NexusXMPP test target and the explicitly identified live-server checks below.

## Verified 2026-09-07

The test executable was rebuilt from source with FPC 3.2.2 using `-B` and all units/binaries directed under `output/`:

```powershell
fpc -B -Fupackages\network\src\xmpp -Fupackages\network\external\synapse -FuC:\lazarus\fpc\3.2.2\units\x86_64-win64\fcl-xml -FuC:\lazarus\fpc\3.2.2\units\x86_64-win64\hash -FUoutput\NexusNetXMPPTests\units -FEoutput\NexusNetXMPPTests\bin packages\network\tests\NexusNetXMPPTests.lpr
```

Result: successful clean compilation. The only warnings were three existing deprecation warnings in bundled `synautil.pas`.

The executable was run with the Git for Windows OpenSSL 3 directory on `PATH`:

```powershell
$env:Path = 'C:\Program Files\Git\mingw64\bin;' + $env:Path
output\NexusNetXMPPTests\bin\NexusNetXMPPTests.exe
```

Result: `NexusNet XMPP tests passed.`

Covered behavior includes the ASCII-only JID and authentication contract, arbitrary stream chunk boundaries, retained namespaces, dispatcher ownership, IQ correlation and synchronous capacity, combined direct-TLS/STARTTLS SRV ordering, OpenSSL primitives, trusted loopback TLS, rejected service identity, rejected issuer, blocked-read interruption, positive and negative SCRAM transcripts, bounded command queues, legal state transitions, stream-management resumption eligibility and expiry, replay reservation and cancellation, rejected-resume reporting, resumed-session identity checks, 32-bit counter wraparound, discovery, roster retrieval/push/subscription storage, connection failure events, connection-thread callbacks, and repeated client connection lifecycles.

Phase 2 coverage includes printable secure stanza/origin IDs, namespace-aware
sibling and nested traversal, typed bodies/subjects/replies/stable IDs/receipts/
all five chat states/delays, valid and invalid Unicode fallback ranges, and
shared forwarded-message validation. Module tests cover the explicit replay
policy, incoming/outgoing ping, outgoing discovery, automatic XEP-0115 lookup,
verified capability hashes, wrong-node and unsupported-hash handling,
default-off automatic receipts, receipt capacity/expiry and explicit accepted,
duplicate, unknown, malformed, expired, and failed outcomes.

File-sharing coverage includes bounded typed XEP-0446 metadata, XEP-0447 SFS
sources, SHA-256 metadata, attachment-only message retention, OOB-only
non-attachment behavior, namespace-targeted fallback removal, duplicate and
multi-file validation, typed XEP-0128 upload limits, XEP-0363 discovery and
slot parsing, allowed-header newline stripping, unknown-header ignoring,
omitted upload purpose, and outbound SFS/OOB/fallback generation.

MUC tests cover instant room creation/configuration, existing-room rejection,
structured configuration failure, bounded history requests/delivery, typed role
and affiliation, status retention, self-presence, room and occupant limits,
Occupant-ID continuity across nickname change, kick removal, structured presence
errors, room-issued reply identifiers, temporary loss, self-ping after accepted
resumption, self-ping confirmation of departure when a service omits required
departure self-presence, and fresh-session rejoin. Carbon tests cover activation, trusted context, spoofed
outer-sender rejection, resumed state, and fresh-session reactivation. MAM tests
cover the selected form filters, forward/backward/last RSM shapes, an owned
operation handle and retained request limits, final RSM metadata, duplicate and
late-result suppression, cancellation capacity release, and a single explicit
limit-exceeded outcome.

## Phase 2 API and limits

Applications add modules before `Connect`; the client owns them afterward.
Typed message and discovery objects passed to callbacks are borrowed for the
duration of the callback. A MAM query returns an `INXXMPPMAMOperation` owned by
the caller and retained by the module until terminal IQ handling. MAM
cancellation is local and does not claim server-side cancellation.

The default in-memory limits are: 128 capability entries with a one-hour TTL;
8 concurrent MAM operations, 100 results per page, 1000 accepted results, and
4 MiB forwarded XML per operation; 32 rooms, 512 occupants per room, and 100
history messages per room; 256 pending receipt correlations with a five-minute
timeout; and 4096 Unicode characters of generated reply fallback. All are
validated through `TNXXMPPClientConfig`; forwarding unwrap depth defaults to
one. Capacity failure occurs before a new
operation or replayable stanza is transmitted; NexusXMPP does not silently
evict pending receipt or MAM work.

The implemented protocol baseline is XEP-0045 1.35.5, XEP-0059 1.0,
XEP-0085 2.1, XEP-0115 1.6.0, XEP-0184 1.4.0, XEP-0199 2.0.1,
XEP-0203 2.0, XEP-0280 1.0.1, XEP-0297 1.0, XEP-0313 1.1.3,
XEP-0359 0.7.0, XEP-0410 1.1.0, XEP-0421 1.0.1, XEP-0428 0.2.1,
XEP-0446 0.2.0, XEP-0447 0.3.1, XEP-0363 1.2.0, XEP-0066 1.6,
XEP-0300 1.0.0, and XEP-0461 0.2.1. Feature availability remains subject to peer/server
advertisement; the library does not infer support from server brand. The
selected XEP-0359, XEP-0428, and XEP-0461 revisions are Experimental and their
public shapes may need deliberate revision when those specifications change.

## Openfire live interoperability

On 2026-09-03, `NexusNetXMPPLiveTest.lpr` was run against a locally controlled
Openfire 5.1.2 server using `nexus.local`, STARTTLS on `127.0.0.1:5222`, and two
temporary test accounts. Passwords were supplied only through environment
variables.

The live target is built with:

```powershell
fpc -B -Fupackages\network\src\xmpp -Fupackages\network\external\synapse -FuC:\lazarus\fpc\3.2.2\units\x86_64-win64\fcl-xml -FuC:\lazarus\fpc\3.2.2\units\x86_64-win64\hash -FUoutput\NexusNetXMPPLiveTest\units -FEoutput\NexusNetXMPPLiveTest\bin packages\network\tests\NexusNetXMPPLiveTest.lpr
```

The manual console target is clean-built with:

```powershell
fpc -B -Fupackages\network\src\xmpp -Fupackages\network\external\synapse -FuC:\lazarus\fpc\3.2.2\units\x86_64-win64\fcl-xml -FuC:\lazarus\fpc\3.2.2\units\x86_64-win64\hash -FUoutput\NexusXMPPConsole\units -FEoutput\NexusXMPPConsole\bin packages\network\examples\xmpp\NexusXMPPConsole.lpr
```

It reads `NEXUS_XMPP_USER1`, `NEXUS_XMPP_PASSWORD1`,
`NEXUS_XMPP_USER2`, `NEXUS_XMPP_PASSWORD2`, `NEXUS_XMPP_CA_FILE`,
`NEXUS_XMPP_HOST`, and `NEXUS_XMPP_PORT`. Setting
`NEXUS_XMPP_EXPECT_TLS_FAILURE=1` runs the single-client negative TLS case.
The positive live target creates its own unique instant room through
`TNXXMPPMUCModule.CreateInstantRoom`. `NEXUS_XMPP_MUC_SERVICE` optionally
overrides the default `conference.<account-domain>` service. Optional
`NEXUS_XMPP_ROOM_NICK1` and `NEXUS_XMPP_ROOM_NICK2` override the otherwise
unique run-specific nicknames. A second observable scenario defaults to the
permanent room `nexus-test@<MUC-service>`; `NEXUS_XMPP_OBSERVABLE_ROOM` can
select a different permanent room.

With the unrelated synthetic test CA, the client rejected Openfire with
`certificate verify failed`. With the checked-in public Openfire certificate,
both clients completed verified TLS, PLAIN authentication explicitly enabled
for this controlled TLS-only test, resource binding, presence, and a message
exchange. The final positive test passed six consecutive runs using unique
resources for each session.

After the completed Phase 2 changes, the rebuilt live target queried
`disco#info` and `disco#items` on `nexus.local`. Openfire returned 53 features
and four server items. It advertised XEP-0280 Carbons but did not advertise
`urn:xmpp:mam:2` for personal MAM. Three simultaneous clients used unique
resources: two resources authenticated as the first temporary account and one
as the second. All three successfully enabled Carbons. The primary first-account
resource sent a typed message to the second account, the second first-account
resource received the validated sent Carbon, and the two accounts completed a
delivery-receipt exchange and a typed composing-state plus reply exchange. The
first account then created and configured a unique instant room at
`conference.nexus.local` through the production MUC API, the second account
joined it, a typed groupchat message was delivered successfully, and both users
left cleanly so the temporary room could be destroyed. Both accounts then
joined the permanent `nexus-test@conference.nexus.local` room, exchanged a
uniquely labeled `NexusXMPP observable permanent-room test ...` message, and
left while preserving the room for direct inspection in Openfire.

The live run identified and corrected two interoperability defects: the stream
framer did not accept Openfire's leading XML declaration, and the transport's
fixed-length receive discarded valid short reads when its timeout elapsed.

The retained Openfire certificate is
`fixtures/xmpp/openfire-nexus-local.crt`. It must be replaced and its fingerprint
reviewed if the controlled server regenerates its certificate.

## Remaining external verification boundary

Prosody and ejabberd remain unverified. Accepted live XEP-0198 resumption across
a forced client-side transport interruption was not exercised by this basic
two-client exchange.
MUC and MAM remain dependent on the explicitly selected Openfire plugins and
configuration. Room creation and basic groupchat are live verified; room MAM is
not claimed because the controlled server did not advertise MAM. No live result
is claimed for a feature that was unavailable or not explicitly configured.
