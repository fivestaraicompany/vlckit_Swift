//
//  VLCKitSwift.swift
//  VLCKit Swift - Pure Swift wrapper for MobileVLCKit
//
//  VLCKitSwift - Swift wrapper target that depends on MobileVLCKit binary
//

import Foundation
import MobileVLCKit

/**
 VLCKitSwift - Main entry point for VLCKit Swift wrapper
 */
public enum VLCKitSwift {
    /// Version string
    public static let version = "3.7.9"
    
    /// Shared library instance
    public static let sharedLibrary = VLCLibrary.sharedLibrary
}
