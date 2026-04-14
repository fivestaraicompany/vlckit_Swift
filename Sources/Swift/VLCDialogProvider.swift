//
//  VLCDialogProvider.swift
//  VLCKit
//
//  VLCDialogProvider - Dialog provider for VLC
//

import Foundation

/**
 VLCDialogProvider - Dialog provider for VLC
 */
public class VLCDialogProvider: NSObject {

    /**
     Create a new dialog provider

     - Parameter library: The library instance
     - Parameter customUI: Whether to use custom UI
     - Returns: A new dialog provider instance
     */
    public convenience init?(library: VLCLibrary?, customUI: Bool) {
        self.init()

#if TARGET_OS_IPHONE
        if customUI {
            return nil // VLCCustomDialogProvider
        }

#if !TARGET_OS_TV
        if #available(iOS 9.0, *) {
            return nil // VLCEmbeddedDialogProvider
        } else {
            return nil // VLCiOSLegacyDialogProvider
        }
#else
        return nil // VLCEmbeddedDialogProvider
#endif
#else
        if customUI {
            return nil // VLCCustomDialogProvider
        } else {
            return nil // No-op implementation for macOS
        }
#endif
    }

    public func postAction(_ buttonNumber: Int, forDialogReference dialogReference: NSValue) {
        // Implemented by respective child class
    }

    public func postUsername(_ username: String?, andPassword password: String?, forDialogReference dialogReference: NSValue, store: Bool) {
        // Implemented by respective child class
    }

    public func dismissDialog(withReference dialogReference: NSValue) {
        // Implemented by respective child class
    }
}
