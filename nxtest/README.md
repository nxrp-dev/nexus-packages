# NexusTest Package

This package contains the reusable NexusTest framework and its C-style module contract.

It includes:

- explicit test registry
- explicit suites
- explicit test cases
- test context/assertions
- structured result objects
- NexusLib JSON-RPC command processor
- typed NexusTest JSON-RPC DTO values
- reusable module/result-store layer
- reusable module/result-store layer

The command-line host and sample module live under `projects/nxtest/host`. The fpGUI
runner lives under `projects/nxtest/ui`.

## Exported module contract

The sample test module exports:

```pascal
function NXTest_Init: Integer; cdecl;
procedure NXTest_Release; cdecl;

function NXTest_ExecuteCommand(
  ARequest: PAnsiChar;
  var AResultId: Integer;
  var AResultSize: Integer
): Integer; cdecl;

function NXTest_ReadResult(
  AResultId: Integer;
  ABuffer: PAnsiChar;
  ABufferSize: Integer;
  var ABytesWritten: Integer
): Integer; cdecl;
```

The command payload is UTF-8 JSON-RPC 2.0 text. Internally, NexusTest uses NexusLib JSON-RPC request classes and typed `TNXJSONValue` descendants for command params and result payloads.

`NXTest_ExecuteCommand` executes the command and stores the response inside the module. It returns a result ID and the exact buffer size needed to read the response.

`AResultSize` includes every byte required by `NXTest_ReadResult`, including the trailing `#0` terminator.

`NXTest_ReadResult` copies and consumes the stored result. A result is single-use. If the supplied buffer is too small, the result is not consumed, and `ABytesWritten` is set to the required size.

No Pascal objects, Pascal strings, records, exceptions, or caller/callee-owned allocations cross the module boundary.

## Supported commands

- `nxtest/getCapabilities`
- `nxtest/listTests`
- `nxtest/runTest`
- `nxtest/runSuite`
- `nxtest/runAll`

## Source dependency

This package uses `packages/nexus-packages/serialization/json/src` and
`packages/nexus-packages/serialization/src` for shared serialization support,
plus `packages/nexus-packages/network/json-rpc/src` for JSON-RPC support. Product hosts and
sample modules consume this package through `packages/nexus-packages/nxtest/src`.

## Package validation

The aggregate test-family build is:

```sh
./projects/nxtest/build_linux.sh
```

See `projects/nxtest/host/README.md` for host and sample-module commands. See
`projects/nxtest/ui/README.md` for the fpGUI runner.

## Current design rule

The DLL boundary exposes intent, not encoding: `NXTest_ExecuteCommand`.

JSON-RPC is the current command contract. The result boundary is deterministic: execute returns a result ID and exact result buffer size; read consumes that specific result only after a successful read.
