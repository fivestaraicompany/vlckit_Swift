/**
 * CLibVLC - Exposes libvlc C API to Swift
 *
 * MobileVLCKit's module.modulemap excludes all vlc/*.h headers,
 * so this shim module re-exports them for use from Swift.
 */

#ifndef CLIBVLC_H
#define CLIBVLC_H

#include <vlc/vlc.h>

#endif /* CLIBVLC_H */
