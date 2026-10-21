# X11 bindings

Follow the Nexus root [AGENTS.md](../../../../AGENTS.md), including its rules on instruction sources.

- Follow Nexus root `AGENTS.md` and `../../../../.ai/standards/pascal.md`.
- Preserve imported C/Pascal author and license notices and namespace wrappers.
- Shared library ABI names belong in `src/tpX11Libraries.pas`.
- Match C widths, signedness and record layout; prove binding fixes with nxtest.
- Keep demonstrations in Nexus Lab `examples/gui/x11`; fixtures belong here.
- Build with NexusFPC/nxbuild; do not add test bridges.
- Record provenance in Nexus root `ATTRIBUTIONS.md`, not a separate attribution page.
