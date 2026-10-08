# NexusTest Package Instructions

These rules apply to `packages/nexus-packages/nxtest`.

- This package owns the reusable NexusTest framework, module ABI, JSON-RPC test commands, registries, suites, cases, contexts, and result storage.
- Product hosts, sample modules, and presentation applications remain outside the package under the top-level `test/` family.
- Follow `../../../.ai/standards/pascal.md` for Object Pascal code.
- Keep the module boundary C-style and do not expose Pascal objects, strings, records, exceptions, or ownership across it.
