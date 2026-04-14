//
//  VLCHelperCode.swift
//  VLCKit
//
//  VLCHelperCode - Helper code for VLC
//

import Foundation

/**
 VLCHelperCode - Helper code for VLC
 */
public class VLCHelperCode: NSObject {

     /**
     Create a new helper code instance
        */
    public override init() {
        super.init()
        }
}

/**
 Convert a C string to an NSString

 - Parameter str: The C string
 - Returns: The NSString
 */
public func toNSStr(_ str: UnsafePointer<CChar>?) -> NSString {
    return str != nil ? NSString(cString: str!) : ""
}
