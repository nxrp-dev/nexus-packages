# NexusScript Package

This package contains the reusable NexusScript mechanism:

- source ranges, values, definitions, modules, and semantic model;
- compiler, import, source-provider, and compilation-session logic;
- analysis, language definitions, normalization, and validation;
- artifact model, bounded JSON, SQLite relational projection, and native Live snapshots;
- external tabular-source handling and manifest processing.

The command-line frontend remains under `projects/nxscript/cli`. The
NexusScript language-server adapter remains under `projects/ls/nxscript`.
Dialect definitions live with their owners. The foundational NexusScript
language and NexusManifest are under `packages/nexus-packages/nxscript/language`; Forge is
under `projects/forge/language`, Bot under
`projects/bothost/language`, Schema under `projects/schema/language`, and
WorkspaceIndex under `tools/workspace-index/language`.

Package tests and parity fixtures are under `test/`.

## Emitters

Artifact emitters derive from `TNexusScriptEmitter`, identify themselves with
`GetFactoryName`, and register through `TNXClassFactory`. Consumers obtain the
typed emitter base through `TNexusScriptEmitterFactory.CreateEmitter`. The
built-in registered names are `json` and `sqlite`. `WriteArtifact(TStream)` is
the common output contract. The filename overload creates a `TFileStream` and
delegates to that stream operation.

Live is an in-memory result, not a stream artifact or a CLI output format.
`TNexusScriptLiveEmitter.Emit` returns a caller-owned snapshot with semantic
objects and real links. See [Live ownership and navigation](doc/live-emitter.md).
Concrete object-reference cycles compile normally. Scalar aliases with no
terminating value still fail compilation. JSON rejects recursive expansion at
emission; Live retains real object links. SQLite keeps its authored relational
projection rather than serializing compiler nodes.

## SQLite emitter

`TNexusScriptSQLiteEmitter` projects the consumer-visible artifact into
relational tables. Definition kinds describe row shapes but never determine
table names. Root and directly nested definitions use their definition names;
definitions contained by properties and all scalar arrays use their property
names. Each table has an emitter-owned `nx_id` primary key. Owner fields name
and reference the actual table containing the owner. Array tables also retain
entry order; scalar arrays store text in `nx_value`, while definition-valued
arrays store definition names and scalar properties.

When a document declares a dialect, the dialect determines the permitted
columns, required scalar values, and empty-array shapes. Without a dialect, the
emitter discovers nullable columns and relationships from all completed values
in the consumer-visible artifact. Empty dialectless arrays contribute no table
because they expose no entry shape. User properties are never replaced by
emitter-generated identity names.

Definition-valued reference properties are saved in `<PropertyName>_id` integer
columns with foreign keys to the existing target table's `nx_id`. Scalar values
keep their original text columns: `Type: "INTEGER"` is saved in `Type`, while
`Type: @...Tables.User` is saved in `Type_id`. Aliases share the target row;
self/mutual references do not duplicate definitions or introduce extra tables.
Reference constraints are deferred until transaction commit so forward and
circular links do not depend on row insertion order.

A referenced row must belong to the output. An imported definition can link to
its included authored row, but a module-only target is not added implicitly.
Each reference column has one target table. Missing/ambiguous target rows,
conflicting target tables, and generated-column name collisions fail emission
rather than silently losing the link. Reference-valued array entries are not
covered by this property-reference projection.

Add the compiled document with `AddDocument`, then call `WriteDatabase` with
the destination filename. The SQLite runtime must be available to the process;
the emitter constructor accepts an optional shared-library path. It is also
available from the command line with `/format=sqlite`. Writing to an existing
database replaces the projected tables in one transaction and leaves unrelated
tables intact. Generic stream emission builds the database in memory and writes
its serialized SQLite bytes to the supplied stream.
