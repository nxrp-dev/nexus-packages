# FCL Process regression tests

- Follow the Nexus repository `AGENTS.md` and `../../../../.ai/standards/pascal.md`.
- Register regression cases with nxtest. Keep destructive and blocking probes
  in the separate fixture process, with bounded parent waits and cleanup.
- Each review finding has its own numbered case. Platform skips must state the
  missing platform or prerequisite; a skip does not prove a failure or a fix.
