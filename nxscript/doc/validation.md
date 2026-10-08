# NexusScript Validation

The Validator is a final NexusScript consumer. It accepts an already compiled
subject document and an already compiled language-definition document through
`TNexusScriptValidator.Validate`. It does not parse source, resolve references,
select validators from filenames, or mutate either document. Language
definitions are normalized through the public read-only
`TNexusScriptLanguageDefinition` model, which the Validator consumes directly.

Compiled documents retain non-owning links to their included documents. The
validator consumes their combined definition view: included subject definitions
are validated, and included language fragments contribute their rule entries.
Module-only roots remain reference/composition dependencies. See
[include presentation](include-presentation.md) for the collection and ownership
rules. The compilation session must outlive validation and its borrowed view.

Language definitions are ordinary NexusScript. The engine assigns meaning to
seven consumer-defined kinds:

- `Language`
- `Definition`
- `Property`
- `Child`
- `Value`
- `Array`
- `Reference`

`Parents` and `Children` are independent. `Parents` restricts where a child
kind may occur. `Children` restricts and counts what a parent accepts. If both
are present, both apply; neither requires a reciprocal declaration.

Validation uses final compiled structure. It separately retains and checks
source form when a rule requires `Text`, `Array`, `Reference`,
`TextComposition`, or `InlineDefinition`. Reference rules inspect the compiled
resolved target and never re-resolve source text.

`AllowedValues` is the finite-value constraint. On a `Value` rule it restricts
effective scalar text. On an `Array` rule it restricts every scalar entry.
Comparisons are case-insensitive, matching the Validator engine's finite
vocabulary. It does not provide predicates, expressions, or pattern matching.

Normalization diagnostics exposed by `TNexusScriptLanguageDefinition` contain
code, message, and source range. The Validator copies those failures into its
own diagnostics, which also contain severity and related source ranges. Codes
beginning `NSV1` describe an invalid language definition. Codes beginning
`NSV2` or `NSV3` describe an invalid subject.

The foundational definition is
`../language/Language.nxscript`. It has no
`dialect`, is compiled normally, normalized by the public model's concrete
language vocabulary,
and then validated against its own normalized rules. No parser mode or second
meta-validator is involved.

Language-definition filenames follow the ordinary three-part convention. The
second component identifies the language definition named by the document's
explicit relative `dialect`:

```text
Language.nxscript
    Schema.Language.nxscript
        Customer.Schema.nxscript

Language.nxscript
    NexusManifest.Language.nxscript
        GeneratedFiles.NexusManifest.nxscript
```

`Language.nxscript` is foundational and therefore has no self-dialect.

The production manifest language definition is shared at
`../language/NexusManifest/NexusManifest.Language.nxscript`.
The production schema language definition is shared at
`../../../projects/schema/language/Schema.Language.nxscript`.

Documents associate their semantic document type explicitly with `dialect`.
The Validator API does not infer, locate, or enforce language-definition
filenames; a
caller may pass a compiled document's `DialectDocument` to `Validate`.
