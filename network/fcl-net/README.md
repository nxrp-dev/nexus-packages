# FCL Net

Relocated intact from NexusFPC on 2026-10-17, after the earlier retirement of
`fpSock`/`HTTPSvlt`. Seven runtime units and their namespace wrappers, platform
includes, original README and useful tests are retained. Demonstrations remain
centralized in Nexus Lab.

Nexus application networking uses Synapse. Its Unix backend currently requires
`netdb`; our shared OpenSSL wrappers and Synapse TLS adapter require `sslbase`.
The other FCL socket APIs remain here pending a deliberate consolidation.
See [the saved review](CODE_REVIEW.md) for the verified consumer inventory,
technical comparison, proven defects and final validation results.

Build from the Nexus root with Nexus nxbuild and the installed NexusFPC:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/network/fcl-net/FCLNet.nxpackage
```

The native recipe builds five common units and the Unix `netdb`/`cnetdb` pair on
Linux. Windows selects the common units and the `src/win` resolver include.
Native Linux is verified during this relocation; other platforms are not claimed
as tested. The existing FPC syntax mode in imported units is not a Delphi support
promise. See [tests](tests/NXTEST.md) for the nxtest runner.

Upstream credit, revision evidence and mixed per-unit licensing are recorded in
[Nexus ATTRIBUTIONS.md](../../../../ATTRIBUTIONS.md#fcl-net). Original notices and
license texts remain with the source. `resolve.pas` has its own GPL header;
`cnetdb.pas` retains Berkeley and DEC notices.

Final native verification: **127/127 nxtest cases and all 26 original standalone
socket cases pass**. The seven-unit package, production transport units and Lab
XMPP example build. All nine proven review findings are fixed. Other platforms
and the separate complete TLS fixture suite remain unverified in this pass.
