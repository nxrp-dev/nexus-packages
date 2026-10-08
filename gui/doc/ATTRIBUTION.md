# Attribution

NexusUI is an original Pascal UI framework developed by Kevin Collins.

This file identifies projects and resources that influenced, assisted, or are used by NexusUI. Attribution here is intended to be precise: credit is granted for the role actually played, not for ownership of NexusUI's current architecture or implementation.

## Attribution Request

Attribution is not required by the MPL-2.0 license.

If NexusUI is useful to your project, attribution is appreciated. A simple note such as the following is enough:

Built with NexusUI by Kevin Collins.

## SimpleGUI

Early NexusUI development used SimpleGUI as a temporary reference and starting scaffold for basic SDL-style UI experimentation.

Credit is given to the SimpleGUI author for the original example project that helped provide an initial point of comparison for:

- creating an SDL-backed window and renderer;
- arranging simple rectangular controls;
- routing basic mouse and keyboard input;
- drawing primitive UI elements;
- demonstrating a minimal retained-control approach.

NexusUI has since been substantially redesigned and rewritten. The current framework architecture, naming, control model, event model, platform abstraction, canvas abstraction, popup system, skinning approach, and component implementations are NexusUI-specific.

SimpleGUI should not be understood as the current architecture, API, design model, or implementation basis of NexusUI.

Reference:

- SimpleGUI project: https://github.com/Free-Pascal-meets-SDL-Website/SimpleGUI

## SDL2

NexusUI currently uses SDL2 as its primary platform backend for windowing, rendering, input, clipboard, timing, images, and font-related services through a Nexus-specific platform abstraction.

SDL2 remains an external dependency and is not part of NexusUI.

References:

- SDL website: https://www.libsdl.org/
- SDL source repository: https://github.com/libsdl-org/SDL

## SDL2_ttf

NexusUI currently uses SDL2_ttf through the SDL2 backend for font loading, font metrics, text measurement, and text rendering.

SDL2_ttf remains an external dependency and is not part of NexusUI.

References:

- SDL2_ttf documentation: https://wiki.libsdl.org/SDL2_ttf
- SDL_ttf source repository: https://github.com/libsdl-org/SDL_ttf

## SDL2_image

NexusUI currently uses SDL2_image through the SDL2 backend for image loading.

SDL2_image remains an external dependency and is not part of NexusUI.

References:

- SDL2_image documentation: https://wiki.libsdl.org/SDL2_image
- SDL_image source repository: https://github.com/libsdl-org/SDL_image

## Free Pascal / Lazarus Ecosystem

NexusUI is developed in Pascal and is influenced by long-standing Pascal UI concepts, including retained controls, component ownership, event methods, and practical desktop control behavior.

Conceptual influence from Delphi, Lazarus/LCL, VCL-style component design, and third-party Pascal systems may be used as behavioral reference material. Such references do not imply code ownership, dependency, or direct derivation unless specifically stated elsewhere.

References:

- Free Pascal: https://www.freepascal.org/
- Lazarus IDE: https://www.lazarus-ide.org/

## AI-Assisted Development

NexusUI has been developed with AI-assisted coding and review support, including ChatGPT and Codex, under Kevin Collins' direction, review, and design control.

AI assistance does not own NexusUI and does not replace the project author's authorship, design judgment, or licensing decisions.

## Virtual TreeView

`packages/gui/external/vtv` contains unmodified Virtual TreeView 6.0.0 source
and resources from Luiz Americo Pereira Camara's Lazarus fork, pinned to commit
`a42d55f18ec293bae853a34ee05c65009b1d2b94`.

Virtual TreeView was written by Mike Lischke; its original copyright identifies
digital publishing AG. The native fpGUI component in `packages/gui/src/vtv`
adapts its node model, lazy initialization, traversal, subtree metrics, and
stable merge sorting. Adapted files retain the upstream MPL-1.1 /
LGPL-2.1-or-later notices. Nexus-authored drawing and input use fpGUI, not LCL.

Source: https://github.com/blikblum/VirtualTreeView-Lazarus
