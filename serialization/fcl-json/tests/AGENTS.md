# FCL JSON regression tests

- Follow the root `AGENTS.md` and `../../../../../.ai/standards/pascal.md`.
- Register review regressions and retained behavioral coverage directly with nxtest.
- Do not add FPCUnit helpers, runners or bridges.
- Run lifetime and malformed-input probes in a bounded fixture process.
- Prove failures against the unchanged source before correcting them.
- Compile generated Pascal and independently parse converted YAML when checking
  those output formats. Missing tools must produce explicit prerequisite skips.
