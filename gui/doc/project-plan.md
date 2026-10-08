# NexusUI Project Plan

## Goal

Build a small, cross-platform, retained-mode Pascal UI framework over SDL2, with clean platform isolation and practical application controls.

## Current Architecture

- `TNXPlatform` owns backend/platform services.
- `TNXCanvas` owns drawing abstraction.
- `TNXControl` owns retained UI control behavior.
- `TNXEvent` types isolate input from SDL2.
- SDL2 is currently the active backend.

## Near-Term Priorities

1. Stabilize core control/event behavior.
2. Add missing standard controls.
3. Improve popup/clipping model.
4. Add theme/style support.
5. Add data context / binding layer.
6. Build a real internal app using NexusUI.

## Core Systems Needed

- Focus management
- Mouse capture
- Popup/input overlay layer
- Keyboard navigation
- Structural Tab traversal
- Theme/style object
- Data context model
- Layout helpers
- Image/icon support
- Basic modal/dialog support

## Controls

### Complete / Initial Version Exists

- `TNXButton` - complete
- `TNXLabel` - complete
- `TNXEditBox` - complete
- `TNXListBox` - complete
- `TNXScrollBar` - complete
- `TNXPanel` - complete
- `TNXProgressBar` - complete
- `TNXMemo`

### Needed

- `TNXGroupBox`
- `TNXPageControl`
- `TNXStatusBar`
- `TNXSpinEdit`
- `TNXGrid`
- `TNXPropertyGrid`
- `TNXColorPicker`
- `TNXFileDialog`
- `TNXCodeEdit` - based on SynEdit
## Data-Aware Layer

- `TNXDataContext`
- `TNXObjectContext`
- `TNXTableContext`
- Field/value state
- Dirty tracking
- Commit/cancel
- Validation
- Control binding

## Backend Work

- Finish SDL2 isolation.
- Add image init/finalize handling.
- Normalize text measurement/rendering.
- Add native handle naming cleanup.
- Keep future backend possibility open.

## First Real App Target

Build one small real tool entirely in NexusUI to expose missing behavior.

Possible target:

- Budget/burn-rate tool
- File/disk usage viewer
- Nexus UI designer/debug tool
