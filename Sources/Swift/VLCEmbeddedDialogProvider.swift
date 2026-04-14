//
//  VLCEmbeddedDialogProvider.swift
//  VLCKit
//
//  VLCEmbeddedDialogProvider - Embedded dialog provider for iOS
//

import Foundation
import UIKit

/**
 VLCEmbeddedDialogProvider - Embedded dialog provider for iOS
 */
public class VLCEmbeddedDialogProvider: VLCDialogProvider {

    private var _libraryInstance: VLCLibrary?

    /**
     Create a new embedded dialog provider

      - Parameter library: The library instance
      - Returns: A new embedded dialog provider instance
      */
    public convenience init?(library: VLCLibrary?) {
        self.init()

        let lib = library ?? VLCLibrary.sharedLibrary
            _libraryInstance = lib

        let cbs = libvlc_dialog_cbs(
            displayErrorCallback: { p_data, psz_title, psz_text in
                let dialogProvider = p_data.map { Unmanaged<VLCEmbeddedDialogProvider>.from($0).takeUnretainedValue() } ?? return

                let title = psz_title.map { String(cString: $0) } ?? ""
                let text = psz_text.map { String(cString: $0) } ?? ""

                DispatchQueue.main.async {
                    dialogProvider.displayError([title, text])
                }
             },
            displayLoginCallback: { p_data, p_id, psz_title, psz_text, psz_default_username, b_ask_store in
                let dialogProvider = p_data.map { Unmanaged<VLCEmbeddedDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
                let dialogProvider = p_data.map { Unmanaged<VLCEmbeddedDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
                let dialogProvider = p_data.map { Unmanaged<VLCEmbeddedDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
                let dialogProvider = p_data.map { Unmanaged<VLCEmbeddedDialogProvider>.from($0).takeUnretainedValue() } ?? return

                DispatchQueue.main.async {
                    dialogProvider.dismissCurrentDialogViewController()
                }
             },
            updateProgressCallback: { p_data, p_id, f_position, psz_text in
                let dialogProvider = p_data.map { Unmanaged<VLCEmbeddedDialogProvider>.from($0).takeUnretainedValue() } ?? return

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
        let alertController = UIAlertController(title: dialogData[0], message: dialogData[1], preferredStyle: .alert)

        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .destructive, handler: nil)
        alertController.addAction(action)

        if alertController.responds(to: #selector(setPreferredAction(_:))) {
            alertController.setPreferredAction(action)
         }

        if let rootViewController = UIApplication.shared.delegate?.window?.rootViewController,
           let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.present(alertController, animated: true, completion: nil)
         }
     }

    private func displayLoginDialog(_ dialogData: [Any]) {
        let alertController = UIAlertController(title: dialogData[1] as? String ?? "",
                                               message: dialogData[2] as? String ?? "",
                                               preferredStyle: .alert)

        var usernameField: UITextField?
        var passwordField: UITextField?

        alertController.addTextField { textField in
            usernameField = textField
            textField.placeholder = NSLocalizedString("User", comment: "")
            if !(dialogData[3] as? String ?? "").isEmpty {
                textField.text = dialogData[3] as? String
             }
         }

        alertController.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = NSLocalizedString("Password", comment: "")
            passwordField = textField
         }

        let loginAction = UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default) { action in
            let username = usernameField?.text ?? ""
            let password = passwordField?.text ?? ""

            libvlc_dialog_post_login(dialogData[0].asPointerValue,
                                     username.isEmpty ? nil : username,
                                     password.isEmpty ? nil : password,
                                     false)
         }
        alertController.addAction(loginAction)

        if alertController.responds(to: #selector(setPreferredAction(_:))) {
            alertController.setPreferredAction(loginAction)
         }

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { action in
            libvlc_dialog_dismiss(dialogData[0].asPointerValue)
         })

        if let dialogData4 = dialogData[4] as? Bool, dialogData4 {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default) { action in
                let username = usernameField?.text ?? ""
                let password = passwordField?.text ?? ""

                libvlc_dialog_post_login(dialogData[0].asPointerValue,
                                         username.isEmpty ? nil : username,
                                         password.isEmpty ? nil : password,
                                         true)
             })
         }

        if let rootViewController = UIApplication.shared.delegate?.window?.rootViewController,
           let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.present(alertController, animated: true, completion: nil)
         }
     }

    private func displayQuestion(_ dialogData: [Any]) {
        let alertController = UIAlertController(title: dialogData[1] as? String ?? "",
                                               message: dialogData[2] as? String ?? "",
                                               preferredStyle: .alert)

        if !(dialogData[4] as? String ?? "").isEmpty {
            alertController.addAction(UIAlertAction(title: dialogData[4] as? String ?? "", style: .cancel) { action in
                libvlc_dialog_post_action(dialogData[0].asPointerValue, 3)
             })
         }

        if !(dialogData[5] as? String ?? "").isEmpty {
            let yesAction = UIAlertAction(title: dialogData[5] as? String ?? "", style: .default) { action in
                libvlc_dialog_post_action(dialogData[0].asPointerValue, 1)
             }
            alertController.addAction(yesAction)

            if alertController.responds(to: #selector(setPreferredAction(_:))) {
                alertController.setPreferredAction(yesAction)
             }
         }

        if !(dialogData[6] as? String ?? "").isEmpty {
            alertController.addAction(UIAlertAction(title: dialogData[6] as? String ?? "", style: .default) { action in
                libvlc_dialog_post_action(dialogData[0].asPointerValue, 2)
             })
         }

        if let rootViewController = UIApplication.shared.delegate?.window?.rootViewController,
           let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.present(alertController, animated: true, completion: nil)
         }
     }

    private func displayProgressDialog(_ dialogData: [Any]) {
        let alertController = UIAlertController(title: dialogData[1] as? String ?? "",
                                                message: dialogData[2] as? String ?? "",
                                                preferredStyle: .alert)

        let isIndeterminate = (dialogData[3] as? Bool) ?? false
        let position = (dialogData[4] as? Float) ?? 0.0
        let cancelString = dialogData[5] as? String ?? ""

        let progressStyle = isIndeterminate ? UISimpleProgressViewStyle.plain : UISimpleProgressViewStyle.bar

        let progressView = UISimpleProgressView(progressViewStyle: progressStyle)
        progressView.tag = 9999
        if !isIndeterminate {
            progressView.progress = position
        }

        alertController.view.addSubview(progressView)

        if !cancelString.isEmpty {
            alertController.addAction(UIAlertAction(title: cancelString, style: .cancel) { action in
                libvlc_dialog_post_action(dialogData[0].asPointerValue, 3)
             })
         }

        if let rootViewController = UIApplication.shared.delegate?.window?.rootViewController,
           let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.present(alertController, animated: true, completion: nil)
         }
     }

    private func updateDisplayedProgressDialog(_ dialogData: [Any]) {
        guard let dialogId = dialogData[0] as? NSValue,
              let position = dialogData[1] as? Float,
              let text = dialogData[2] as? String else { return }

        if let rootViewController = UIApplication.shared.delegate?.window?.rootViewController,
           let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                self.displayProgressDialog(dialogData)
            }
         }
     }

    private func dismissCurrentDialogViewController() {
        if let rootViewController = UIApplication.shared.delegate?.window?.rootViewController,
           let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.dismiss(animated: true, completion: nil)
         }
     }
}

// MARK: - Extension

extension Any {
    var asPointerValue: UnsafeMutableRawPointer? {
        return self as? NSValue?.map { $0.pointerValue } ??
               nil
     }
}
