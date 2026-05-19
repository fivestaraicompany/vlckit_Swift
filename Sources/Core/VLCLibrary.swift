import Foundation

public extension VLCLibrary {
    static var shared: VLCLibrary {
        return VLCLibrary.sharedLibrary()
    }
}

public extension VLCLibrary {
    static var currentErrorMessage: String? {
        get { return VLCLibrary.currentErrorMessage }
        set { VLCLibrary.currentErrorMessage = newValue }
    }
}
