import Foundation

public extension VLCDialogProvider {
        @objc var customRenderer: VLCCustomDialogRendererProtocol? {
            get { _customRenderer }
            set { _customRenderer = newValue }
        }
    private var _customRenderer: VLCCustomDialogRendererProtocol?
    
        @objc convenience init(library: VLCLibrary?) {
            self.init(library: library, customUI: false)
        }
    
        @objc convenience init(library: VLCLibrary?, customUI: Bool) {
            let lib = library ?? VLCLibrary.shared
            if customUI {
                self.init(library: lib, customUI: true)
            } else {
                self.init(library: lib, customUI: false)
            }
        }
    
        @objc func postUsername(_ username: String, andPassword password: String, forDialogReference dialogReference: NSValue, store: Bool) {
            libvlc_dialog_post_login(dialogReference.pointerValue!, username, password, store ? 1 : 0)
        }
    
        @objc func postAction(_ buttonNumber: Int32, forDialogReference dialogReference: NSValue) {
            libvlc_dialog_post_action(dialogReference.pointerValue!, buttonNumber)
        }
    
        @objc func dismissDialog(withReference dialogReference: NSValue) {
            libvlc_dialog_dismiss(dialogReference.pointerValue!)
        }
}

public extension VLCCustomDialogRendererProtocol {
    @objc func showError(title: String, message: String) { }
    @objc func showLogin(title: String, message: String, defaultUsername: String?, askingForStorage: Bool, reference: NSValue) { }
    @objc func showQuestion(title: String, message: String, type: VLCDialogQuestionType, cancelString: String?, action1String: String?, action2String: String?, reference: NSValue) { }
    @objc func showProgress(title: String, message: String, isIndeterminate: Bool, position: Float, cancelString: String?, reference: NSValue) { }
    @objc func updateProgress(withReference reference: NSValue, message: String?, position: Float) { }
    @objc func cancelDialog(withReference reference: NSValue) { }
}
