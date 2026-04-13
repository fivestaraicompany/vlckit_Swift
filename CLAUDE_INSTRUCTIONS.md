# VLCKit Swift Migration — Claude Code Work Instructions

## Project Overview

This project is a company fork of the upstream MobileVLCKit/VLCKit project. The goal is to independently evolve the library with a modern Swift-first architecture while maintaining full functionality of the underlying libVLC media engine.

**Repository:** `vlckit_Swift`
**Upstream:** VideoLAN VLCKit (Objective-C)
**Package Manager:** Swift Package Manager (SPM) with binary target for MobileVLCKit xcframework
**Minimum Targets:** iOS 13+, macOS 10.15+, tvOS 13+

---

## Work Streams

### 1. Swift Package Manager (SPM) Modernization

**Goal:** Ensure the project is fully SPM-native with clean module structure.

**Tasks:**
- Maintain `Package.swift` as the single source of truth for build configuration
- Remove Xcode project files (`MobileVLCKit.xcodeproj`, `VLCKit.xcodeproj`) once SPM is fully functional
- Organize sources under `Sources/` with proper module boundaries
- Ensure all public API types are exported through a single SPM target
- Add a pure-Swift wrapper target that depends on the binary xcframework target
- Configure proper platform conditionals (`#if os(iOS)`, `#if os(macOS)`, `#if os(tvOS)`)
- Remove `Packaging/` directory scripts once SPM replaces all distribution methods

**Validation:**
```bash
swift build
swift package resolve
```

---

### 2. Objective-C to Swift Migration

**Goal:** Migrate all Objective-C (`.m`) source files to Swift, one file at a time.

**Current State:**
Each class currently exists as a pair: `VLC<ClassName>.m` (Objective-C) and `VLC<ClassName>.swift` (Swift). The Swift files may be partial or complete rewrites.

**Migration Order (by dependency, bottom-up):**

| Phase | Files | Rationale |
|-------|-------|-----------|
| 1 - Foundational | `VLCTime`, `VLCHelperCode`, `VLCLogMessageFormatter` | No dependencies on other VLC types |
| 2 - Core Types | `VLCLibrary`, `VLCMedia`, `VLCAudio` | Core types used by everything else |
| 3 - Collections | `VLCMediaList`, `VLCMediaLibrary` | Depend on VLCMedia |
| 4 - Playback | `VLCMediaPlayer`, `VLCMediaListPlayer` | Depend on Media + Library |
| 5 - Filters & EQ | `VLCFilter`, `VLCAdjustFilter`, `VLCAudioEqualizer` | Depend on MediaPlayer |
| 6 - Dialog | `VLCDialogProvider`, `VLCCustomDialogProvider`, `VLCEmbeddedDialogProvider`, `VLCiOSLegacyDialogProvider` | UI layer |
| 7 - Advanced | `VLCMediaThumbnailer`, `VLCRendererDiscoverer`, `VLCRendererItem`, `VLCTranscoder` | Higher-level features |
| 8 - Streaming | `VLCStreamOutput`, `VLCStreamSession` | Streaming utilities |
| 9 - Video Output | `VLCVideoCommon`, `VLCVideoLayer`, `VLCVideoView` | Platform-specific video rendering |
| 10 - Events | `VLCEventsConfiguration`, `VLCEventsHandler` | Event system |
| 11 - Static Lib | `StaticLibVLC` | Bootstrap / linking glue |
| 12 - Discovery | `VLCMediaDiscoverer` (currently `.m` only, no `.swift` yet) | Last standalone ObjC file |

**Per-File Migration Procedure:**

1. **Read** the existing `.m` file and corresponding `.swift` file thoroughly
2. **Read** the corresponding `.h` header in `Headers/Public/` and `Headers/Internal/`
3. **Identify** all libVLC C function calls (e.g., `libvlc_*`) — these will use Swift C interop
4. **Migrate** the Objective-C implementation to Swift:
   - Convert `@property` to Swift stored/computed properties
   - Convert `init`/`dealloc` to Swift `init`/`deinit`
   - Convert delegate patterns to Swift protocols or closures
   - Replace `NSNotificationCenter` usage with `NotificationCenter` or Combine where appropriate
   - Replace `dispatch_*` GCD calls with Swift concurrency (`async/await`, `Task`, actors) where safe
   - Keep `Unmanaged`, `UnsafeMutablePointer`, and other C interop where needed for libVLC calls
   - Use `@objc` attributes only if backward compatibility with ObjC callers is still required
5. **Verify** the Swift file compiles: `swift build`
6. **Delete** the `.m` file after successful migration
7. **Update or delete** the corresponding `.h` header file
8. **Run tests** if available

**Rules:**
- Never break the public API signature without explicit approval
- Preserve thread-safety semantics from the original ObjC code
- Keep `libvlc_*` C function calls — do NOT attempt to rewrite libVLC internals
- Use `Optional` instead of nullable ObjC pointers
- Prefer value types (`struct`, `enum`) over reference types where the ObjC original used simple data holders
- Use Swift enums with raw values to replace ObjC `NS_ENUM` / `typedef enum`

---

### 3. Objective-C Header Cleanup

**Goal:** Remove all Objective-C header files once their corresponding Swift migration is complete.

**Tasks per header:**
1. Confirm the `.m` file has been fully migrated and deleted
2. Ensure no remaining source files `#import` the header
3. Delete the `.h` file from `Headers/Public/` or `Headers/Internal/`
4. Remove umbrella header references in `MobileVLCKit.h`, `TVVLCKit.h`, `VLCKit.h`
5. Once all headers are removed, delete the `Headers/` directory entirely

**Validation:**
```bash
# Ensure no remaining ObjC imports
grep -r '#import' Sources/ Headers/
grep -r '#include' Sources/ Headers/
```

---

### 4. C Code Swift Migration (Where Beneficial)

**Goal:** Migrate C-level glue code to Swift where it improves safety and maintainability, while keeping performance-critical C code intact.

**Candidates for Swift migration:**
- `StaticLibVLC.m` → Pure Swift module initialization
- Any C helper functions that serve as ObjC/C glue between Swift and libVLC
- String manipulation or data conversion utilities currently in C

**Do NOT migrate to Swift:**
- Direct `libvlc_*` API calls that benefit from zero-overhead C interop
- Performance-critical codec or rendering callbacks
- Low-level memory management in hot paths (e.g., video frame handling)
- Anything inside the `libvlc/` directory (upstream VLC patches)

**Swift C Interop Guidelines:**
- Use `@convention(c)` for C function pointer callbacks
- Use `withUnsafeMutablePointer` / `withUnsafeBufferPointer` for safe pointer access
- Wrap `OpaquePointer` types in Swift classes with proper `deinit` for resource cleanup
- Use `CChar` / `CInt` type aliases for clarity at the boundary

---

### 5. C-Level Performance Optimization

**Goal:** Optimize remaining C code and Swift-C bridge for maximum performance.

**Areas to optimize:**

#### 5.1 Memory Management
- Audit `malloc`/`free` patterns — replace with stack allocation where buffer sizes are known
- Minimize unnecessary copying across the Swift-C boundary
- Use `ContiguousArray` instead of `Array` for C interop buffers
- Pool frequently allocated objects (e.g., media descriptors, event structs)

#### 5.2 Callback Overhead
- Minimize Swift closure captures in C callbacks to reduce retain/release overhead
- Use `Unmanaged.passUnretained` for hot-path callbacks where ownership is guaranteed
- Batch event notifications instead of firing per-frame where applicable

#### 5.3 Threading
- Ensure libVLC callbacks do not hop threads unnecessarily
- Use `DispatchQueue` with proper QoS labels for media processing
- Avoid `@objc` dynamic dispatch in performance-critical paths — use `final` classes
- Mark performance-critical classes and methods as `final` to enable devirtualization

#### 5.4 Build Optimization
- Enable Whole Module Optimization (`-whole-module-optimization`) in release builds
- Use `@inlinable` for small, frequently called bridge functions
- Consider `@frozen` for public enums/structs that won't change

**Profiling:**
```bash
# Use Instruments to profile
xcrun xctrace record --template 'Time Profiler' --launch <app>
```

---

### 6. Example Apps Migration

**Goal:** Migrate example apps to modern Swift.

**Tasks:**
- Migrate `Examples/iOS/DropIn-Player/` from ObjC to Swift
- Migrate `Examples/iOS/SimplePlayback/` from ObjC to Swift
- Migrate `Examples/macOS/` examples from ObjC to Swift
- Remove `Examples/iOS/GLEssentials/` (deprecated OpenGL, replace with Metal example if needed)
- Update `Examples/iOS/SwiftSimplePlayback/` to use latest Swift APIs and remove bridging header
- Remove all bridging headers once ObjC dependencies are eliminated

---

### 7. Test Infrastructure

**Goal:** Build a Swift test suite to validate migration correctness.

**Tasks:**
- Create unit tests under `Tests/` for each migrated class
- Test public API parity: every method that existed in ObjC must exist in Swift
- Test C interop: verify libVLC function calls produce correct results
- Test thread safety: concurrent access patterns that were safe in ObjC must remain safe
- Add integration tests for media playback, streaming, and transcoding

---

## General Rules for All Work

1. **One class per commit** — migrate a single `.m` → `.swift` per commit for clean history
2. **Build must pass** after every commit: `swift build` must succeed
3. **No force unwraps** (`!`) except where guaranteed by libVLC API contracts
4. **No `Any` type erasure** — use generics or protocols instead
5. **Preserve LGPL license headers** in all migrated files
6. **Document libVLC C function usage** with inline comments explaining the C API behavior
7. **Use Swift naming conventions** (camelCase methods, UpperCamelCase types) even when the ObjC original used different naming

## File Structure Target State

```
vlckit_Swift/
├── Package.swift
├── Sources/
│   ├── VLCLibrary.swift
│   ├── VLCMedia.swift
│   ├── VLCMediaPlayer.swift
│   ├── ... (all pure Swift, no .m files)
│   └── VLCLibVLCBridging.swift    # C interop layer
├── Tests/
│   └── VLCKitTests/
│       ├── VLCLibraryTests.swift
│       ├── VLCMediaTests.swift
│       └── ...
├── Examples/
│   ├── iOS/
│   │   └── SwiftPlayback/         # Modern Swift example
│   └── macOS/
│       └── SwiftPlayer/           # Modern Swift example
└── libvlc/
    └── patches/                    # Upstream VLC patches (do not modify)
```

## Quick Reference: Repeatable Commands

```bash
# Check for remaining ObjC files
find Sources/ -name "*.m" | sort

# Check for remaining ObjC headers
find Headers/ -name "*.h" | sort

# Verify Swift build
swift build 2>&1

# Count migration progress
echo "ObjC files remaining: $(find Sources/ -name '*.m' | wc -l)"
echo "Swift files: $(find Sources/ -name '*.swift' | wc -l)"

# Find libVLC C function usage
grep -rn 'libvlc_' Sources/*.swift

# Find remaining ObjC imports
grep -rn '#import\|#include' Sources/ Headers/
```
