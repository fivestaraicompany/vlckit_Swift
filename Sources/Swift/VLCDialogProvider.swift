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

    public func postAction(_ buttonNumber: Int, forDialogReference dialogReference: NSValue) {
        // Implemented by subclass
    }

    public func postUsername(_ username: String?, andPassword password: String?, forDialogReference dialogReference: NSValue, store: Bool) {
        // Implemented by subclass
    }

    public func dismissDialog(withReference dialogReference: NSValue) {
        // Implemented by subclass
    }
}
