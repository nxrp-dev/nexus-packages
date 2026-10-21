# RTL Unicode package

Follow the Nexus root [AGENTS.md](../../../AGENTS.md), including its rules on instruction sources.

Follow `../../../.ai/standards/pascal.md` for Pascal changes. Preserve original
source/data notices and central provenance in `../../../ATTRIBUTIONS.md`.
Byte-oriented UTF-8 buffers use explicit AnsiChar/AnsiString in both compiler
modes. Do not change process code-page policy merely by importing a helper.
The package depends on the selected matching RTL, never the compiler bootstrap.
Tests use nxtest directly; keep large conformance inputs compressed.
