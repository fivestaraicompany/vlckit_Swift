//
//  VLCEmbeddedDialogProvider.swift
//  VLCKit
//
//  VLCEmbeddedDialogProvider - Embedded dialog provider for iOS
//

import Foundation
import CLibVLC
#if canImport(UIKit) && !os(watchOS)
import UIKit

/**
 VLCEmbeddedDialogProvider - Embedded dialog provider for iOS
 */
public class VLCEmbeddedDialogProvider: VLCDialogProvider {

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
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .destructive, handler: nil)
        alertController.addAction(action)
        alertController.preferredAction = action
        presentAlert(alertController)
    }

    private func displayLoginDialog(title: String, text: String, username: String?, askStore: Bool, dialogId: OpaquePointer?) {
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .alert)

        var usernameField: UITextField?
        var passwordField: UITextField?

        alertController.addTextField { textField in
            usernameField = textField
            textField.placeholder = NSLocalizedString("User", comment: "")
            if let username = username, !username.isEmpty {
                textField.text = username
            }
        }

        alertController.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = NSLocalizedString("Password", comment: "")
            passwordField = textField
        }

        let loginAction = UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default) { _ in
            let user = usernameField?.text ?? ""
            let pass = passwordField?.text ?? ""
            libvlc_dialog_post_login(dialogId,
                                     user.isEmpty ? nil : user,
                                     pass.isEmpty ? nil : pass,
                                     false)
        }
        alertController.addAction(loginAction)
        alertController.preferredAction = loginAction

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
            libvlc_dialog_dismiss(dialogId)
        })

        presentAlert(alertController)
    }

    private func displayQuestion(title: String, text: String, cancel: String?, action1: String?, action2: String?, dialogId: OpaquePointer?) {
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .alert)

        if let cancel = cancel, !cancel.isEmpty {
            alertController.addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
                libvlc_dialog_post_action(dialogId, 3)
            })
        }

        if let action1 = action1, !action1.isEmpty {
            let yesAction = UIAlertAction(title: action1, style: .default) { _ in
                libvlc_dialog_post_action(dialogId, 1)
            }
            alertController.addAction(yesAction)
            alertController.preferredAction = yesAction
        }

        if let action2 = action2, !action2.isEmpty {
            alertController.addAction(UIAlertAction(title: action2, style: .default) { _ in
                libvlc_dialog_post_action(dialogId, 2)
            })
        }

        presentAlert(alertController)
    }

    private func presentAlert(_ alert: UIAlertController) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            let presenter = rootVC.presentedViewController ?? rootVC
            presenter.present(alert, animated: true, completion: nil)
        }
    }
}

#endif
