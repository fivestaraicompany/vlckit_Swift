//
//  VLCiOSLegacyDialogProvider.swift
//  VLCKit
//
//  VLCiOSLegacyDialogProvider - iOS legacy dialog provider for iOS 7
//

import Foundation
import UIKit

/**
 VLCiOSLegacyDialogProvider - iOS legacy dialog provider for iOS 7
 */
public class VLCiOSLegacyDialogProvider: VLCDialogProvider {

    private var _libraryInstance: VLCLibrary?

    /**
     Create a new iOS legacy dialog provider

     - Parameter library: The library instance
     - Returns: A new iOS legacy dialog provider instance
     */
    public convenience init?(library: VLCLibrary?) {
        self.init()

        let lib = library ?? VLCLibrary.sharedLibrary
        _libraryInstance = lib

        let cbs = libvlc_dialog_cbs(
            displayErrorCallback: { p_data, psz_title, psz_text in
                let dialogProvider = p_data.map { Unmanaged<VLCiOSLegacyDialogProvider>.from($0).takeUnretainedValue() } ?? return

                let title = psz_title.map { String(cString: $0) } ?? ""
                let text = psz_text.map { String(cString: $0) } ?? ""

                DispatchQueue.main.async {
                    dialogProvider.displayError([title, text])
                  }
              },
            displayLoginCallback: { p_data, p_id, psz_title, psz_text, psz_default_username, b_ask_store in
                let dialogProvider = p_data.map { Unmanaged<VLCiOSLegacyDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
              },
            displayQuestionCallback: { p_data, p_id, psz_title, psz_text, i_type, psz_cancel, psz_action1, psz_action2 in
                let dialogProvider = p_data.map { Unmanaged<VLCiOSLegacyDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
              },
            displayProgressCallback: { p_data, p_id, psz_title, psz_text, b_indeterminate, f_position, psz_cancel in
                let dialogProvider = p_data.map { Unmanaged<VLCiOSLegacyDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
              },
            cancelCallback: { p_data, p_id in
                print("cancelCallback: %i", p_id)
              },
            updateProgressCallback: { p_data, p_id, f_position, psz_text in
                let dialogProvider = p_data.map { Unmanaged<VLCiOSLegacyDialogProvider>.from($0).takeUnretainedValue() } ?? return

                let text = psz_text.map { String(cString: $0) } ?? ""

                DispatchQueue.main.async {
                    dialogProvider.updateDisplayedProgressDialog([
                        NSValue(value: p_id),
                        NSNumber(value: f_position),
                        text
                      ])
                  }
              }
          )

        libvlc_dialog_set_callbacks(_libraryInstance?.instance, &cbs, Unmanaged.passRetained(self).toOpaque())

        super.init()
      }

    deinit {
        libvlc_dialog_set_callbacks(_libraryInstance?.instance, NULL, NULL)
      }

    private func displayError(_ dialogData: [String]) {
        let alert = VLCBlockingAlertView(title: dialogData[0],
                                          message: dialogData[1],
                                          delegate: nil,
                                          cancelButtonTitle: NSLocalizedString("OK", comment: ""),
                                          otherButtonTitles: nil)
        alert.completion = nil
        alert.show()
      }

    private func displayLoginDialog(_ dialogData: [Any]) {
        let otherTitles: [String] = [
            NSLocalizedString("Login", comment: ""),
             (dialogData[4] as? Bool ?? false) ? NSLocalizedString("Store", comment: "") : nil
         ].compactMap { $0 }

        let alert = VLCBlockingAlertView(title: dialogData[1] as? String ?? "",
                                          message: dialogData[2] as? String ?? "",
                                          delegate: nil,
                                          cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
                                          otherButtonTitles: otherTitles)
        alert.alertViewStyle = .loginAndPasswordInput

        var weakAlert: VLCBlockingAlertView?
        alert.completion = { [weak self] cancelled, buttonIndex in
            weakAlert = nil
            if !cancelled {
                let username = self?.textField(atIndex: 0).text ?? ""
                let password = self?.textField(atIndex: 1).text ?? ""
                libvlc_dialog_post_login(dialogData[0].asPointerValue,
                                          username.isEmpty ? "" : username,
                                          password.isEmpty ? "" : password,
                                          buttonIndex != alert.firstOtherButtonIndex)
              } else {
                libvlc_dialog_dismiss(dialogData[0].asPointerValue)
              }
          }
        alert.delegate = alert
        alert.show()
      }

    private func displayQuestion(_ dialogData: [Any]) {
        let otherTitles: [String] = [
            dialogData[4] as? String ?? nil,
            dialogData[5] as? String ?? nil,
            dialogData[6] as? String ?? nil
         ].compactMap { $0 }

        let alert = VLCBlockingAlertView(title: dialogData[1] as? String ?? "",
                                          message: dialogData[2] as? String ?? "",
                                          delegate: nil,
                                          cancelButtonTitle: dialogData[4] as? String ?? nil,
                                          otherButtonTitles: otherTitles)
        alert.completion = { cancelled, buttonIndex in
            if cancelled {
                libvlc_dialog_post_action(dialogData[0].asPointerValue, 3)
              } else {
                libvlc_dialog_post_action(dialogData[0].asPointerValue, Int(buttonIndex))
              }
          }
        alert.delegate = alert
        alert.show()
      }

    private func displayProgressDialog(_ dialogData: [Any]) {
        print("displayProgressDialog: \(dialogData)")
      }

    private func updateDisplayedProgressDialog(_ dialogData: [Any]) {
        print("updateDisplayedProgressDialog: \(dialogData)")
      }

    private func textField(atIndex index: Int) -> UITextField? {
        return nil
      }
}

/**
 VLCBlockingAlertView - Blocking alert view for iOS 7
 */
public class VLCBlockingAlertView: UIAlertView {

    public var completion: ((Bool, Int) -> Void)?
    public var alertViewStyle: UIAlertViewStyle = .default
    public var firstOtherButtonIndex: Int {
        return cancelButtonIndex + 1
      }

    public convenience init(title: String,
                            message: String,
                            delegate: UIAlertViewDelegate?,
                            cancelButtonTitle: String?,
                            otherButtonTitles: [String]?) {
        self.init(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle ?? "", otherButtonTitles: otherButtonTitles ?? [])

        if let otherButtonTitles = otherButtonTitles {
            for buttonTitle in otherTitles {
                addButton(title: buttonTitle)
              }
          }
      }

    public func show() {
        show()
      }

    public func textField(atIndex index: Int) -> UITextField? {
        return nil
      }
}

// MARK: - Extension

extension Any {
    var asPointerValue: UnsafeMutableRawPointer? {
        return self as? NSValue?.map { $0.pointerValue } ??
               nil
      }
}

extension UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex: Int) {
          // No-op
      }
}
