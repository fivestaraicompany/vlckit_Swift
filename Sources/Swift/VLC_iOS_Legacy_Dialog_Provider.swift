//
//  VLCiOSLegacyDialogProvider.swift
//  VLCKit
//
//  VLCiOSLegacyDialogProvider - iOS legacy dialog provider
//  Note: UIAlertView is deprecated. This file is kept for API compatibility
//  but uses UIAlertController internally on modern iOS.
//

import Foundation
import CLibVLC
#if canImport(UIKit) && !os(watchOS)
import UIKit

/**
 VLCiOSLegacyDialogProvider - iOS legacy dialog provider
 */
public class VLCiOSLegacyDialogProvider: VLCDialogProvider {

    private var _libraryInstance: VLCLibrary?

    public init(library: VLCLibrary?) {
        super.init()
        _libraryInstance = library ?? VLCLibrary.sharedLibrary
    }

    deinit {
        if let instance = _libraryInstance?.instance {
            libvlc_dialog_set_callbacks(instance, nil, nil)
        }
    }

    private func displayError(title: String, text: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            self.presentAlert(alert)
        }
    }

    private func displayLoginDialog(title: String, text: String, username: String?, askStore: Bool, dialogId: OpaquePointer?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)

            var usernameField: UITextField?
            var passwordField: UITextField?

            alert.addTextField { tf in
                usernameField = tf
                tf.placeholder = NSLocalizedString("User", comment: "")
                if let username = username, !username.isEmpty {
                    tf.text = username
                }
            }

            alert.addTextField { tf in
                passwordField = tf
                tf.isSecureTextEntry = true
                tf.placeholder = NSLocalizedString("Password", comment: "")
            }

            alert.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default) { _ in
                let user = usernameField?.text ?? ""
                let pass = passwordField?.text ?? ""
                libvlc_dialog_post_login(dialogId,
                                         user.isEmpty ? nil : user,
                                         pass.isEmpty ? nil : pass,
                                         false)
            })

            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                libvlc_dialog_dismiss(dialogId)
            })

            self.presentAlert(alert)
        }
    }

    private func displayQuestion(title: String, text: String, cancel: String?, action1: String?, action2: String?, dialogId: OpaquePointer?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)

            if let cancel = cancel, !cancel.isEmpty {
                alert.addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
                    libvlc_dialog_post_action(dialogId, 3)
                })
            }

            if let action1 = action1, !action1.isEmpty {
                alert.addAction(UIAlertAction(title: action1, style: .default) { _ in
                    libvlc_dialog_post_action(dialogId, 1)
                })
            }

            if let action2 = action2, !action2.isEmpty {
                alert.addAction(UIAlertAction(title: action2, style: .default) { _ in
                    libvlc_dialog_post_action(dialogId, 2)
                })
            }

            self.presentAlert(alert)
        }
    }

    private func presentAlert(_ alert: UIAlertController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let presenter = rootVC.presentedViewController ?? rootVC
        presenter.present(alert, animated: true)
    }
}

#endif
