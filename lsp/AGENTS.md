# Shared LSP Library Instructions

These rules apply to `packages/nexus-packages/lsp`.

- Follow `../../../.ai/standards/pascal.md` for Object Pascal code.
- This folder owns only language-neutral LSP protocol values and process infrastructure.
- It must not depend on Pascal analysis, NexusScript, either concrete language server, or a concrete request registry.
- Concrete request execution, documents, analysis, indexing, and language-specific protocol extensions remain owned by their server.

