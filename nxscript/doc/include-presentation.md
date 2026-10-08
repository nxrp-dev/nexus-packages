# Generating from included systems

`include` contributes definitions to one presentation. `module` makes definitions
available for references and composition. A file used through both contributes
once, while references still resolve to the original definitions. A separately
composed definition remains a separate output item.

To generate tables from Inventory and Customer, the entry file can contain:

```nexusscript
include "Inventory.nxscript";
include "Customer.nxscript";
```

The Mustache template can iterate all contributed tables, including tables
nested inside system roots:

```mustache
{{#_nx.Collections.Table}}
create table {{_nx.Name}} ...;
{{/_nx.Collections.Table}}
```

Collections use the actual definition kind, without automatic pluralization.
Each item has the normal definition JSON: its properties, nested definitions,
and `_nx` metadata. Fields and indexes stay inside their table; collecting a
table does not combine its members with another table's members. Named root
lookup remains available for explicit constants and intentionally grouped output.

The presentation gathers the entry document followed by included documents in
declaration order, recursively. A shared included document contributes once.
Module-only definitions do not contribute independently. Reference values keep
their original target metadata and are not counted as additional declarations.
Source provenance is retained in each definition's `_nx.SourceRange`.

Inclusion does not merge same-named roots or rewrite lexical identity. Distinct
roots with the same name are errors. Nested names retain their owner scope, so
different tables can each contain a field called `ID`. A kind collection is an
iteration view, not a new namespace for resolving references.

Reusable bases placed in an included file are exposed just like any other
definition. Keep them in module-only files when they should not be generated.
There is no automatic classification or exclusion of templates.

## Reference projection boundary

In JSON output, a reference to a definition exposes a bounded projection.
Scalar properties, recursively scalar arrays, and ordinary child definitions
are retained. Arrays containing definitions or definition references are omitted
entirely, including mixed arrays and nested arrays with a structural leaf.
The same projection rule applies recursively to child definitions.

This deliberately prevents expansion through structural arrays from following
self-references or mutually referring definitions indefinitely. The original
semantic definition remains complete. Compilation, Live, and SQLite retain
the actual reference target and its full arrays; no projection is stored in
the compiled graph. JSON consumers can use an explicit path to the original
when they need a value omitted from its bounded projection.

For example, given a module providing `Table Base` with
`Fields: [Field ID { Type: Integer; }];`:

```nexusscript
Table Concrete (Base) {
    Original: @Base;
    OriginalIDType: @Base.Fields.ID.Type;
    Fields: [Field ID { Type: UUID; }];
}
```

In JSON, `Original` identifies `Base` but omits `Fields`.
`OriginalIDType` is `Integer`, while Concrete's own ID type is `UUID`.
Inclusion does not change this JSON rule. Aliases preserve the same bounded
projection; they do not expand it into a complete copy of the original.
Direct self/mutual object references are valid source. If JSON would expand
them recursively, emission reports a recursive-projection error. Independent
references to one target are not cycles. Scalar/value dependency cycles remain
compiler errors; source-loading and composition cycle rules are unchanged.

## Included language rules

A declared language can include independently named language fragments:

```nexusscript
include "pieces/*.nxscript";
Language Forge {
    UnknownDefinitions: Reject;
    Definitions: [];
}
```

Each fragment contributes its own `Language` root and `Definitions` array.
Validation gathers those rule entries through the same included-definition view;
the master need not name or inherit from the fragment roots. Duplicate rule
names are errors, not overrides. The declared language supplies the unknown-kind
policy; an explicitly supplied fragment policy must agree. Invalid included
subject definitions are also validated.

Dialect file lookup is unchanged: inclusion does not choose the document's
dialect or introduce a discovery registry.

## Verification

```powershell
lazbuild -B packages\nexus-packages\nxscript\test\NexusScriptTests.lpi
& .\output\NexusScript\console-tests\x86_64-win64\NexusScriptTests.exe
```

The console runner executes the existing NexusScript cases plus include
collection, mixed module/include, and included-language regressions. Fixtures
under `tests/fixtures/include-collections` demonstrate the nine-table example,
diamond includes, repeated includes, references, composition, collisions, and
language rules loaded from separate files.
