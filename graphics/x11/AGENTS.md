# X11 bindings

- Follow Nexus root `AGENTS.md` and `../../../../.ai/standards/pascal.md`.
- Preserve imported C/Pascal author and license notices and namespace wrappers.
- Shared library ABI names belong in `src/tpX11Libraries.pas`.
- Match C widths, signedness and record layout; prove binding fixes with nxtest.
- Keep demonstrations in Nexus Lab `examples/gui/x11`; fixtures belong here.
- Build with NexusFPC/nxbuild; do not add Lazarus projects or test bridges.
- Record provenance in Nexus root `ATTRIBUTIONS.md`, not a separate attribution page.
