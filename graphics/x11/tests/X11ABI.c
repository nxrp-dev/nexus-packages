/* Copyright (c) 2026 Kevin Collins.
 * SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
 * Optional independent ABI reference; requires native X11 development headers.
 */
#include <stddef.h>
#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xrender.h>
#include <X11/extensions/XInput.h>
#include <X11/extensions/XKBstr.h>
#include <X11/extensions/XKBgeom.h>
#include <fontconfig/fontconfig.h>
#define SHOW(t) printf("%s=%zu\n", #t, sizeof(t))
int main(void) {
    SHOW(Glyph); SHOW(GlyphSet); SHOW(Picture); SHOW(PictFormat);
    SHOW(XRenderPictFormat); SHOW(XRenderPictureAttributes);
    SHOW(FcType); SHOW(FcValue); SHOW(XkbKTMapEntryRec);
    SHOW(XkbStateRec); SHOW(XkbClientMapRec); SHOW(XkbServerMapRec);
    SHOW(XkbDescRec); SHOW(XkbShapeRec); SHOW(XkbShapeDoodadRec);
    SHOW(XkbGeometryRec); SHOW(XkbDeviceInfoRec);
    printf("XRenderPictFormat.type=%zu\n", offsetof(XRenderPictFormat, type));
    printf("XRenderPictureAttributes.dither=%zu\n", offsetof(XRenderPictureAttributes, dither));
    return 0;
}
