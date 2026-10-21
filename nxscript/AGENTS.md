# NexusScript Package Instructions

Follow the Nexus root [AGENTS.md](../../../AGENTS.md), including its rules on instruction sources.

These rules apply to `packages/nexus-packages/nxscript`.

- This package owns the reusable NexusScript language model, compiler, source/dependency session, analysis, validation, artifact model, JSON serialization, external-data handling, and manifest processing.
- Command-line process behavior remains under `projects/nxscript/cli`.
- Language-server composition remains under `projects/ls/nxscript`.
- Product dialects and scripts live with their owners; WorkspaceIndex is under `tools/workspace-index/language`.
- Keep product-owned schemas, templates and task definitions with their owners.
  Runnable examples live in the sibling Nexus Lab repository.
- Follow `../../../.ai/standards/pascal.md` for Object Pascal code.
