# Native Virtual TreeView Port

- Follow `../../../../../.ai/standards/pascal.md` for Nexus-authored code.
- This is a native fpGUI adaptation of the pinned Lazarus Virtual TreeView source
  under `../../external/vtv`. Retain upstream attribution and license notices in
  adapted implementation files.
- Do not introduce LCL, VCL, or direct operating-system drawing/input calls.
- Keep `TNXVirtualTreeView` a small Nexus descendant of the native component.
- Do not change `TNXTreeView` or migrate its consumers as part of this port.
