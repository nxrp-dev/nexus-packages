# Native Live output

`obNexusScriptLive` owns the snapshot object API; `tpNexusScriptLive` owns its
value-kind enum. Neither unit depends on a product, fpGUI, or a stream emitter.

```pascal
lSession := TNexusScriptCompilationSession.Create;
try
  if not lSession.CompileFile(lFileName) then
    raise Exception.Create(lSession.LastError);
  lLive := TNexusScriptLiveEmitter.Emit(lSession.EntryCompiler.CompiledDocument);
finally
  lSession.Free;
end;
try
  lRoot := lLive.FindDefinition('Root');
  lTarget := lRoot.FindProperty('Link').Value.AsDefinition;
  lText := lTarget.FindProperty('Text').Value.AsText;
finally
  lLive.Free;
end;
```

This is a snapshot, not a borrowed compiler view. The caller frees the document.
The document owns every node once. Roots, definitions, children, parents, array
entries, and reference targets are borrowed navigation links. Do not free nodes
individually. A consumer retaining a node must also retain its document.

`Value.AsText` and `Value.AsDefinition` require the corresponding effective
kind; invalid access raises an exception. `Items` preserves ordered entries;
`FindItem` looks up their effective names. Whole-array aliases share the same
entry objects. `Reference.Target` retains the immediate typed Live node
(definition, property, or value), whereas `AsDefinition` gives the effective
definition reached through aliases. Receiver names and original declared names
are separate. Source, contributor, and reference ranges remain available.

Shared targets remain shared pointers. Self/mutual definition references close
real cycles. Two emissions are independent documents, even when their source
is the same compilation. No source session or original compiled pointer is
needed afterward. Emission rejects incomplete values and frees partial output
on failure.

`Roots` is public contribution membership. `Definitions` also contains reachable
private targets and their retained context. A private module is not promoted
to a public contribution merely because a reference reaches it. Definition
list order is copying/navigation order, not dependency execution order.

The semantic graph contains full structural arrays. JSON's Mustache projection
rules do not apply here. Source-loading, composition, and scalar-evaluation
cycle rules still apply at compilation.

Setup is the initial product consumer: `TNXSetupLoader` compiles with the common
analysis/session, emits Live, then explicitly maps it into native Setup domain
classes. The Setup document owns that Live snapshot for provenance. There is
no arbitrary class mapper, reverse loader, fake `WriteArtifact`, or
`/format=live` disk format. Forge is not migrated or modified.
