# NexusScript structural editor

`TNXScriptEditor` (`packages2/nexus-packages/gui/src/obNXScriptEditor.pas`) descends from
`TNXVirtualTreeView`. It builds its tree and editing choices from the source
document and its normalized NexusScript dialect. It does not use the language
server, an LCL control, or a separate editor schema.

## Run the demonstration

From the repository root:

```powershell
lazbuild packages2/nexus-packages/gui/examples/nxscript-editor/NexusScriptEditorDemo.lpi
& output/NexusScriptEditorDemo/x86_64-win64/NexusScriptEditorDemo.exe
```

An optional filename opens another dialect-backed NexusScript file. The bundled
`Demo.nxscript` and `Editor.Language.nxscript` exercise Boolean, Integer, finite
choices, references, text composition, named arrays, and inline definitions.
The lower pane shows the current source; it is deliberately read-only. Save is
explicit. `--smoke` opens, paints, and closes the demonstration without saving.

## Editing

- F2 or double-click edits a value or definition name. Boolean and finite-value
  rules use choice editors. Enter commits; Escape cancels. Rejected values remain
  available for correction and do not change the document.
- The first column edits scalar array-entry names when the dialect permits them;
  definition kinds and property names are not editable cells.
- Right-click, Insert, or Actions offers declared missing properties, permitted
  child/root kinds, allowed source forms, array insertion, and removal. Unknown
  properties are offered separately only when the dialect allows them.
- Creation prompts for required properties and minimum child definitions.
  Array name policies and size limits, child count limits, source forms, scalar
  kinds, and finite choices constrain the available actions. The existing
  compiler and dialect validator decide whether the complete edit is valid.
- Ctrl+Z and Ctrl+Y undo/redo accepted edits. Renaming does not automatically
  rewrite references: a rename that breaks them is rejected.

References and compositions remain source expressions, not substituted text.
More complex values use a source-syntax dialog with compiler validation rather
than a second grammar. Reference choices include ordinary compiled definitions
and their properties; other valid reference paths can be supplied through
`SetNodeSource` or the document API. Choice lists are not a substitute for final
validation, including reference categories and cycles.

## Embedding

Add `packages2/nexus-packages/gui/src`, `packages2/nexus-packages/gui/src/vtv`, and `packages/nxscript/src`, plus
the normal NXScript and fpGUI dependency paths shown in the demo project.
Initialize fpGUI before constructing the control.

```pascal
lEditor := TNXScriptEditor.Create(lForm);
lEditor.Align := alClient;
lEditor.OnEditRejected := @EditRejected;
lEditor.LoadFile(lFileName);
```

The control owns its `Document: TNexusScriptEditDocument`. Hosts can inspect its
`Dirty`, `Valid`, and `Diagnostics` properties and call `Save`, `Undo`, or `Redo`.
Use the control's `OnDocumentChanged` and `OnEditRejected` events; its internal
document and tree callbacks maintain the projection and must not be replaced.
Call `EndEditNode` and check its Boolean result before saving a pending cell.

`SetNodeValue` accepts decoded text for literals or a definition name;
`SetNodeSource` accepts one value in source syntax. Tree nodes are invalidated
by accepted edits; reacquire them after a change. `GetPropertyChoices`,
`GetDefinitionChoices`, and `GetSourceForms` expose the same choices to hosts.

`TNexusScriptEditDocument` is GUI-independent and belongs to the NXScript
package. It owns the entry-file bytes, compilation analysis, diagnostics, and
undo/redo history. Each candidate is recompiled and validated before adoption.
Rejected edits leave source, revision, and history unchanged. Model objects and
dialect rules are borrowed until the next accepted edit or load; offsets address
the current revision only. The source provider outlives its analysis/session.

Untouched byte ranges are retained, including comments and line endings. Saving
writes those bytes directly, without pretty-printing or newline normalization.
Removing an item also removes its delimiters and the intervening source span;
comments in that removed span are not relocated. Insertions use the platform's
line ending and simple indentation rather than reformatting the file.

## Current boundary

Only the entry file's explicit definitions/properties are writable. Imported
files are compiled normally but not edited, and inherited/effective values are
not flattened into the source tree. File directives, inheritance declarations,
and target headers have no structural editing commands in this control.
Undeclared definition kinds are not offered by the creation menu. The current
grammar permits inline definitions in arrays, not as direct property values.
No custom dialect UI annotations, automatic reference rewriting, or language
server integration are introduced.

## Verification

```powershell
lazbuild packages2/nexus-packages/gui/test/NexusScriptEditorTests.lpi
& output/NexusScriptEditorTests/x86_64-win64/NexusScriptEditorTests.exe
```

The 12 checked Win64 tests cover projection/choices, byte-preserving edits and
save, atomic rejection, required properties and child rules, array bounds and
names, inline definitions, references/compositions, undo/redo, reload lifetime,
and native choice-to-text editing. Existing VTV, NXScript, and PackageManager
suites also pass. The demonstration's startup/paint/close smoke check passes;
interactive visual acceptance remains a user check.
