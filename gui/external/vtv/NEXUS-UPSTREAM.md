# Virtual TreeView upstream source

- Repository: https://github.com/blikblum/VirtualTreeView-Lazarus
- Branch: `lazarus-master`
- Commit: `a42d55f18ec293bae853a34ee05c65009b1d2b94`
- Source version: 6.0.0
- Imported: 2026-10-05

`Source`, `Resources`, and the upstream README, installation notes, and change
log are unmodified copies from that revision. Upstream license and copyright
notices remain in the source files.

The upstream widget depends on LCL. Nexus does not compile it into native fpGUI
applications. Native adaptations belong in `../../src/vtv`; the Nexus-named
control belongs in `../../src/obNXVirtualTreeView.pas`.
