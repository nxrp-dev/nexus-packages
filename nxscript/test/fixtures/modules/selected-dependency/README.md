# Selected module dependency reference regression

Status: corrected and verified, 2026-09-15.

## Minimal reproduction

`dependency.nxscript`:

```nexusscript
Thing Dependency { Value: original; }
```

`middle.nxscript`:

```nexusscript
module Dependency "dependency.nxscript";
Thing Middle { Link: @Dependency; }
```

`selected.nxscript`:

```nexusscript
module Middle "middle.nxscript";
Thing Entry { Link: @Middle; }
```

Before correction, compiling middle succeeded but compiling selected failed with
`Unresolved reference @Dependency`. No Schema, Forge, dialect, includes, arrays,
Firebird, or relocated paths are involved. `whole.nxscript` is the control: importing
all of middle succeeds because Dependency is also imported into the consumer.

`shadowed.nxscript` imports Middle selectively and imports a different Dependency
from `other-dependency.nxscript`. Before correction it compiled, but Middle.Link resolved to that
consumer dependency, whose Value is `unrelated`, instead of the original target.

## Automated regression

Registered in the existing NexusScript.Compiler suite:

- SelectedModuleDependencyReference: declaring-module and whole-import controls
  pass; selective import is expected to compile while keeping Dependency private.
- SelectedModuleDependencyCapture: an unrelated same-named consumer import must
  not retarget Middle.Link.

- SelectedModuleDependencyOwnership: free the producer before compiling the consumer,
  then clear import inputs; external scalar/property/array references and shared
  dependency identity survive while internal references bind to the receiving graph.

All three regressions and the full 60-test compiler suite pass with no leaks.
The 12-test language-server suite also passes with no leaks. Existing expectations
for bounded projections and internal composition rebinding remain unchanged.

The imported root owns a private completed dependency graph. Reference edges are
remapped to owned copies, shared targets stay shared, and no dependency roots are
added to consumer lookup or emitted collections. Compilation copies this context
again so it is independent of the compiler's import inputs.

From the repository root:

```powershell
lazbuild packages/nexus-packages/nxscript/test/NexusScriptTests.lpi
& ./output/NexusScript/console-tests/x86_64-win64/NexusScriptTests.exe
```

The minimal input can also be compiled independently with the existing CLI:

```powershell
& ./output/NexusScript/x86_64-win64/NexusScript.exe /input=packages\nexus-packages\nxscript\test\fixtures\modules\selected-dependency\selected.nxscript
```

## Traced cause

Source anchors, before the compiler correction:

1. `core/obNexusScriptSession.pas:350-380` compiles the module first, selects Middle,
   then passes only that definition to AddImportedDefinition. File discovery works.
2. `core/obNexusScriptCompiler.pas:2311-2318` clones that definition with
   CloneDefinitionForRebinding(..., True). Compilation clones it again at line 2270.
3. `CloneValueForRebinding`, lines 1079-1105, copies source text and structural input
   but drops resolved targets, effective values, and evaluation completion state.
   Detaching source objects is deliberate, not accidental file-path loss.
4. On evaluating Entry.Link, EvaluateValue calls BindDefinition(Middle), line 2171.
   That evaluates the copied @Dependency again.
5. ResolveMember, lines 1678-1688, searches the current scope and the consumer's
   FCompiledDocument imported roots. It has no original module dependency context.
   Without a consumer Dependency it fails; with one, it silently binds to that one.

The root selector is doing its visibility job correctly. The failure is treating
an imported definition's external bindings as if they could always be reconstructed
from the receiving document's visible roots.

## Correction boundaries

Preserve module-local dependency identity without exposing unselected definitions
as consumer roots or rendered artifacts. Distinguish that from intentional rebinding
of internal references during composition. Preserve bounded reference projection.

Do not simply retain borrowed producer pointers: the existing
CompiledTransferCloning test frees the producer before compiling its consumer and
requires transferred data to remain independently usable. A correction must give
retained dependency context appropriate ownership and preserve that regression.
Do not solve the problem by requiring every caller to import private dependencies.

The existing tests cover a selected root without an external dependency, and an
owned transfer with references internal to the transferred graph. Neither covered
this selected-root/external-dependency combination or same-name capture.
