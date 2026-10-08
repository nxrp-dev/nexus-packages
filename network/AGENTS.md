# NexusLib Network Package Instructions

These rules apply to `packages/nexus-packages/network`.

## Standards

- For Object Pascal / Free Pascal code, follow `../../../.ai/standards/pascal.md`.
- Treat this folder as the Nexus networking library family.

## Architecture

- Keep protocol code small, explicit, and testable.
- Keep transport, protocol parsing, storage, and session orchestration separated when they have different failure modes.
- Do not make network-facing code depend on UI, language-server, schema, or project-specific behavior.
- Prefer deterministic tests for protocol and storage behavior. Use live network behavior only when a test explicitly requires it.
