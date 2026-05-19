import Foundation

/// Placeholder class to ensure linking works.
/// The actual libvlc symbols are resolved through the C bridging header.
@objc public final class StaticLibVLC {
     @objc public static func ensure() {
          // This class exists to ensure the framework links
          // against the required libvlc symbols
     }
}
