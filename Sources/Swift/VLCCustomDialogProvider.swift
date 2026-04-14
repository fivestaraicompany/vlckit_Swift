//
//  VLCCustomDialogProvider.swift
//  VLCKit
//
//  VLCCustomDialogProvider - Custom dialog provider for VLC
//

import Foundation
import CLibVLC

/**
 Protocol for custom dialog renderer
 */
@objc public protocol VLCCustomDialogRenderer: AnyObject {
    func showErrorWithTitle(_ title: String, message: String)
    func showLoginWithTitle(_ title: String, message: String, defaultUsername: String?, askingForStorage: Bool, withReference reference: NSValue)
    func showQuestionWithTitle(_ title: String, message: String, type: UInt, cancelString: String?, action1String: String?, action2String: String?, withReference reference: NSValue)
    func showProgressWithTitle(_ title: String, message: String, isIndeterminate: Bool, position: Float, cancelString: String?, withReference reference: NSValue)
    func updateProgressWithReference(_ reference: NSValue, message: String, position: Float)
    func cancelDialogWithReference(_ reference: NSValue)
}

/**
 VLCCustomDialogProvider - Custom dialog provider for VLC
 */
public class VLCCustomDialogProvider: VLCDialogProvider {

    private var _libraryInstance: VLCLibrary?
    private var _customRenderer: (any VLCCustomDialogRenderer)?

    public init(library: VLCLibrary?) {
        super.init()
        _libraryInstance = library ?? VLCLibrary.sharedLibrary
    }

    deinit {
        if let instance = _libraryInstance?.instance {
            libvlc_dialog_set_callbacks(instance, nil, nil)
        }
    }

    public var customRenderer: (any VLCCustomDialogRenderer)? {
        get { return _customRenderer }
        set { _customRenderer = newValue }
    }

    public func displayError(_ title: String, text: String) {
        customRenderer?.showErrorWithTitle(title, message: text)
    }

    public func displayLoginDialog(title: String, text: String, username: String?, askStore: Bool, reference: NSValue) {
        customRenderer?.showLoginWithTitle(title, message: text, defaultUsername: username, askingForStorage: askStore, withReference: reference)
    }

    public override func postUsername(_ username: String?, andPassword password: String?, forDialogReference dialogReference: NSValue, store: Bool) {
        let dialogId = OpaquePointer(dialogReference.pointerValue)
        guard let username = username, let password = password else {
            libvlc_dialog_dismiss(dialogId)
            return
        }

        libvlc_dialog_post_login(dialogId, username, password, store)
    }

    public override func postAction(_ buttonNumber: Int, forDialogReference dialogReference: NSValue) {
        let dialogId = OpaquePointer(dialogReference.pointerValue)
        libvlc_dialog_post_action(dialogId, Int32(buttonNumber))
    }

    public override func dismissDialog(withReference dialogReference: NSValue) {
        let dialogId = OpaquePointer(dialogReference.pointerValue)
        libvlc_dialog_dismiss(dialogId)
    }
}
