//
//  VLCCustomDialogProvider.swift
//  VLCKit
//
//  VLCCustomDialogProvider - Custom dialog provider for VLC
//

import Foundation

/**
 Protocol for custom dialog renderer
 */
public protocol VLCCustomDialogRenderer: AnyObject {
    func showErrorWithTitle(_ title: String, message: String)
    func showLoginWithTitle(_ title: String, message: String, defaultUsername: String?, askingForStorage: Bool, withReference NSValue)
    func showQuestionWithTitle(_ title: String, message: String, type: UInt, cancelString: String?, action1String: String?, action2String: String?, withReference NSValue)
    func showProgressWithTitle(_ title: String, message: String, isIndeterminate: Bool, position: Float, cancelString: String?, withReference NSValue)
    func updateProgressWithReference(_ reference: NSValue, message: String, position: Float)
    func cancelDialogWithReference(_ reference: NSValue)
}

/**
 VLCCustomDialogProvider - Custom dialog provider for VLC
 */
public class VLCCustomDialogProvider: VLCDialogProvider {

    private var _libraryInstance: VLCLibrary?
    private var _customRenderer: (any VLCCustomDialogRenderer)?

        /**
         Create a new custom dialog provider

          - Parameter library: The library instance
          - Returns: A new custom dialog provider instance
          */
    public convenience init?(library: VLCLibrary?) {
        self.init()

        let lib = library ?? VLCLibrary.sharedLibrary
           _libraryInstance = lib

        let cbs = libvlc_dialog_cbs(
            displayErrorCallback: displayErrorCallback,
            displayLoginCallback: displayLoginCallback,
            displayQuestionCallback: displayQuestionCallback,
            displayProgressCallback: displayProgressCallback,
            cancelCallback: cancelCallback,
            updateProgressCallback: updateProgressCallback
         )

        libvlc_dialog_set_callbacks(_libraryInstance!.instance, &cbs, Unmanaged.passRetained(self).toOpaque())

         customRenderer = nil
           }

    deinit {
        libvlc_dialog_set_callbacks(_libraryInstance?.instance, NULL, NULL)
            }

    public var customRenderer: (any VLCCustomDialogRenderer)? {
        get { return _customRenderer }
        set { _customRenderer = newValue }
           }

    public func displayError(_ dialogData: [String]) {
        guard let renderer = customRenderer else { return }

        if renderer.responds(to: #selector(showErrorWithTitle(message:))) {
            renderer.showErrorWithTitle(dialogData[0], message: dialogData[1])
              }
           }

    public func displayLoginDialog(_ dialogData: [Any]) {
        guard let renderer = customRenderer else { return }

        if renderer.responds(to: #selector(showLoginWithTitle(message:defaultUsername:askingForStorage:withReference:))) {
            let username = (dialogData[3] as? String)?.isEmpty == true ? nil : dialogData[3] as? String
            renderer.showLoginWithTitle(dialogData[1] as? String ?? "",
                                        message: dialogData[2] as? String ?? "",
                                        defaultUsername: username,
                                        askingForStorage: (dialogData[4] as? Bool) ?? false,
                                        withReference: dialogData[0] as? NSValue ?? NSValue())
              }
           }

    public func postUsername(_ username: String?, andPassword password: String?, forDialogReference dialogReference: NSValue, store: Bool) {
        guard let username = username, let password = password else {
            libvlc_dialog_dismiss(dialogReference.pointerValue)
            return
              }

        libvlc_dialog_post_login(dialogReference.pointerValue,
                                  username,
                                  password,
                                  store)
           }

    public func displayQuestion(_ dialogData: [Any]) {
        guard let renderer = customRenderer else { return }

        if renderer.responds(to: #selector(showQuestionWithTitle(message:type:cancelString:action1String:action2String:withReference:))) {
            renderer.showQuestionWithTitle(dialogData[1] as? String ?? "",
                                            message: dialogData[2] as? String ?? "",
                                            type: (dialogData[3] as? UInt) ?? 0,
                                            cancelString: (dialogData[4] as? String)?.isEmpty == true ? nil : dialogData[4] as? String,
                                            action1String: (dialogData[5] as? String)?.isEmpty == true ? nil : dialogData[5] as? String,
                                            action2String: (dialogData[6] as? String)?.isEmpty == true ? nil : dialogData[6] as? String,
                                            withReference: dialogData[0] as? NSValue ?? NSValue())
              }
           }

    public func postAction(_ buttonNumber: Int, forDialogReference dialogReference: NSValue) {
        libvlc_dialog_post_action(dialogReference.pointerValue, buttonNumber)
           }

    public func displayProgressDialog(_ dialogData: [Any]) {
        guard let renderer = customRenderer else { return }

        if renderer.responds(to: #selector(showProgressWithTitle(message:isIndeterminate:position:cancelString:withReference:))) {
            renderer.showProgressWithTitle(dialogData[1] as? String ?? "",
                                            message: dialogData[2] as? String ?? "",
                                            isIndeterminate: (dialogData[3] as? Bool) ?? false,
                                            position: (dialogData[4] as? Float) ?? 0.0,
                                            cancelString: (dialogData[5] as? String)?.isEmpty == true ? nil : dialogData[5] as? String,
                                            withReference: dialogData[0] as? NSValue ?? NSValue())
              }
           }

    public func updateDisplayedProgressDialog(_ dialogData: [Any]) {
        guard let renderer = customRenderer else { return }

        if renderer.responds(to: #selector(updateProgressWithReference(message:position:))) {
            renderer.updateProgressWithReference(dialogData[0] as? NSValue ?? NSValue(),
                                                  message: dialogData[1] as? String ?? "",
                                                  position: (dialogData[2] as? Float) ?? 0.0)
              }
           }

    public func cancelDialog(_ dialogId: NSValue) {
        guard let renderer = customRenderer else { return }

        if renderer.responds(to: #selector(cancelDialogWithReference:)) {
            renderer.cancelDialogWithReference(dialogId)
              }
           }

    public func dismissDialog(withReference dialogReference: NSValue) {
        libvlc_dialog_dismiss(dialogReference.pointerValue)
           }
}

// MARK: - Callbacks

private func displayErrorCallback(p_data: UnsafeMutableRawPointer?, psz_title: UnsafePointer<CChar>?, psz_text: UnsafePointer<CChar>?) {
    let dialogProvider = p_data.map { Unmanaged<VLCCustomDialogProvider>.from($0).takeUnretainedValue() } ?? return

    let title = psz_title.map { String(cString: $0) } ?? ""
    let text = psz_text.map { String(cString: $0) } ?? ""

    DispatchQueue.main.async {
        dialogProvider.displayError([title, text])
         }
}

private func displayLoginCallback(p_data: UnsafeMutableRawPointer?, p_id: OpaquePointer?, psz_title: UnsafePointer<CChar>?, psz_text: UnsafePointer<CChar>?, psz_default_username: UnsafePointer<CChar>?, b_ask_store: Bool) {
    let dialogProvider = p_data.map { Unmanaged<VLCCustomDialogProvider>.from($0).takeUnretainedValue() } ?? return

    let title = psz_title.map { String(cString: $0) } ?? ""
    let text = psz_text.map { String(cString: $0) } ?? ""
    let username = psz_default_username.map { String(cString: $0) } ?? ""

    DispatchQueue.main.async {
        dialogProvider.displayLoginDialog([
            NSValue(value: p_id),
            title,
            text,
            username,
            NSNumber(value: b_ask_store)
         ])
         }
}

private func displayQuestionCallback(p_data: UnsafeMutableRawPointer?, p_id: OpaquePointer?, psz_title: UnsafePointer<CChar>?, psz_text: UnsafePointer<CChar>?, i_type: UInt32, psz_cancel: UnsafePointer<CChar>?, psz_action1: UnsafePointer<CChar>?, psz_action2: UnsafePointer<CChar>?) {
    let dialogProvider = p_data.map { Unmanaged<VLCCustomDialogProvider>.from($0).takeUnretainedValue() } ?? return

    let title = psz_title.map { String(cString: $0) } ?? ""
    let text = psz_text.map { String(cString: $0) } ?? ""
    let cancel = psz_cancel.map { String(cString: $0) } ?? ""
    let action1 = psz_action1.map { String(cString: $0) } ?? ""
    let action2 = psz_action2.map { String(cString: $0) } ?? ""

    DispatchQueue.main.async {
        dialogProvider.displayQuestion([
            NSValue(value: p_id),
            title,
            text,
            NSNumber(value: i_type),
            cancel,
            action1,
            action2
         ])
         }
}

private func displayProgressCallback(p_data: UnsafeMutableRawPointer?, p_id: OpaquePointer?, psz_title: UnsafePointer<CChar>?, psz_text: UnsafePointer<CChar>?, b_indeterminate: Bool, f_position: Float, psz_cancel: UnsafePointer<CChar>?) {
    let dialogProvider = p_data.map { Unmanaged<VLCCustomDialogProvider>.from($0).takeUnretainedValue() } ?? return

    let title = psz_title.map { String(cString: $0) } ?? ""
    let text = psz_text.map { String(cString: $0) } ?? ""
    let cancel = psz_cancel.map { String(cString: $0) } ?? ""

    DispatchQueue.main.async {
        dialogProvider.displayProgressDialog([
            NSValue(value: p_id),
            title,
            text,
            NSNumber(value: b_indeterminate),
            NSNumber(value: f_position),
            cancel
         ])
         }
}

private func cancelCallback(p_data: UnsafeMutableRawPointer?, p_id: OpaquePointer?) {
    let dialogProvider = p_data.map { Unmanaged<VLCCustomDialogProvider>.from($0).takeUnretainedValue() } ?? return

    DispatchQueue.main.async {
        dialogProvider.cancelDialog(NSValue(value: p_id))
         }
}

private func updateProgressCallback(p_data: UnsafeMutableRawPointer?, p_id: OpaquePointer?, f_position: Float, psz_text: UnsafePointer<CChar>?) {
    let dialogProvider = p_data.map { Unmanaged<VLCCustomDialogProvider>.from($0).takeUnretainedValue() } ?? return

    let text = psz_text.map { String(cString: $0) } ?? ""

    DispatchQueue.main.async {
        dialogProvider.updateDisplayedProgressDialog([
            NSValue(value: p_id),
            text,
            NSNumber(value: f_position)
         ])
         }
}

// MARK: - Extension

extension OpaquePointer {
    var pointerValue: UnsafeMutableRawPointer? {
        return self
          }
}
