# Native fpGUI Virtual TreeView

`TNXVirtualTreeView` in `../obNXVirtualTreeView.pas` is a thin descendant of
`TfpgVirtualStringTree`. It is independent of the existing `TNXTreeView`; no
existing application is migrated by adding this control.

The native component adapts Virtual TreeView 6.0.0 node records, linked-list
operations, lazy initialization, aggregate subtree metrics, and stable merge
sorting from the Lazarus fork pinned in `../../external/vtv/NEXUS-UPSTREAM.md`.
The LCL widget itself is not compiled. Painting, input, focus, scrollbars, and
the inline editor use fpGUI directly.

## Using the control

Add `packages2/nexus-packages/gui/src` and `packages2/nexus-packages/gui/src/vtv` to the unit search path,
alongside the normal fpGUI paths. Use `obNXVirtualTreeView` for the Nexus class,
`tpVTV` for node and option types, and `obVTVTree` for callback sender types.

Initialize fpGUI normally before constructing controls. The control owns its
node allocations, header, options, scrollbars, and inline editor. Images supplied
by `OnGetImage` are borrowed, not freed by the tree.

Set `NodeDataSize` before adding nodes (or supply `OnGetNodeDataSize`). Node data
is zero-initialized, caller-defined storage. Use `OnInitNode` to populate it and
`OnFreeNode` to release managed fields or owned objects. `GetNodeData` does not
initialize a node; initialized traversal, painting, and expansion do.

```pascal
lTree := TNXVirtualTreeView.Create(lForm);
lTree.NodeDataSize := SizeOf(TMyNodeData);
lTree.OnInitNode := @InitNode;
lTree.OnFreeNode := @FreeNode;
lTree.OnGetText := @GetText;
lTree.RootNodeCount := 100000;
```

Root node records are allocated immediately; node contents are initialized on
demand. `OnInitChildren` supplies a branch's child count when it is first
expanded. `BeginUpdate` / `EndUpdate` coalesce layout and change notification.

## Implemented surface

- Node data, lazy children, insertion/deletion, traversal, visibility/filtering,
  variable row heights, expansion, and stable sibling sorting.
- Multi-column headers, column resizing, text/image callbacks, and clipped
  owner-drawn cells.
- Mouse and keyboard selection, multi-selection, range selection, incremental
  search, native scrolling, checkbox/radio states, and optional tristate tracking.
- Inline fpGUI text editing through `OnNewText`, with protected hooks for
  per-cell edit permission, initial text, finite choices, and commit validation.
- fpGUI fonts, named colors, checkbox/radio drawing, and focus drawing. This
  uses the active fpGUI style, including TNXSkin, but adds no Lua render handler.

This is not complete upstream API parity. Drag/drop, structured clipboard data,
streaming, printing, accessibility, fixed/reordered columns, animated expansion,
and multiline cell layout have not been ported. Unsupported options are not
offered as inert compatibility switches.

`EndEditNode` returns `False` when a descendant rejects a commit and leaves the
editor open for correction. `CancelEditNode` discards the pending value.
Choice and text editors share the native lifecycle; focus-exit notifications
from an inactive editor cannot commit a newly opened cell. Commit callbacks may
rebuild the tree, so callers must reacquire node pointers after accepted edits.

`../obNXScriptEditor.pas` uses these hooks for dialect-driven structural editing;
see `../../examples/nxscript-editor/README.md` for its interface and boundaries.

## Verification

`../../test/NexusVirtualTreeViewTests.lpi` is a standalone Win64 test runner.
Its memory-backed canvas checks cell/header clipping and buffer guard bytes
without opening a visible application window. The suite also exercises lazy
initialization and viewport painting with 100,000 roots.

The runner calls `fpgApplication.Initialize` once before executing tests;
fpGUI's `IsInitialized` flag describes backend readiness, not toolkit setup.
The checked Win64 run passes all 19 tests with no heap leaks. Wheel-scrolling
checks cover both axes, repeated/reverse scrolling, range clamping, content
coordinates, and row/header hit testing.

For an interactive TNXSkin demonstration, build and run
`../../examples/virtual-treeview/NexusVirtualTreeViewDemo.lpi`. It provides
100,000 lazy root branches, five children per expanded branch, checkboxes,
multi-selection, column resizing, sorting, and F2 text editing.

## License

Adapted files retain Virtual TreeView's MPL-1.1 / LGPL-2.1-or-later notice.
Independent Nexus files carry the repository's MPL-2.0 header. The vendored
upstream source and resources are unchanged.
