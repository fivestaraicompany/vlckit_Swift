import Foundation

@objc public final class VLCLogMessageFormatter: NSObject, VLCLogMessageFormatting {
    
     @objc public var contextFlags: VLCLogContextFlag = .none
     @objc public var customContext: AnyObject? {
         get { return _customContext }
         set {
             if newValue != nil {
                 contextFlags = contextFlags | .custom
               }
             _customContext = newValue
           }
       }
    private var _customContext: AnyObject?
    
    private func prefix(from level: VLCLogLevel) -> String {
        switch level {
        case .info: return "INF"
        case .error: return "ERR"
        case .warning: return "WARN"
        case .debug: return "DBG"
         }
       }
    
    public func format(with message: String, logLevel: VLCLogLevel, context: VLCLogContext?) -> String {
        guard let ctx = context, contextFlags != .none else {
            return "[\(prefix(from: logLevel))] \(message)\n"
           }
        
        var contextDesc = ""
        if contextFlags.contains(.module), let objType = ctx.objectType, let mod = ctx.module {
            contextDesc += " [\(mod)/\(objType)]"
           }
        if contextFlags.contains(.fileLocation), let file = ctx.file {
            contextDesc += " [\(file):\(ctx.line)]"
           }
        if contextFlags.contains(.callingFunction), let function = ctx.function {
            contextDesc += " [from \(function)]"
           }
        if contextFlags.contains(.custom), let custom = customContext,
           custom.responds(to: Selector(("description"))) {
            contextDesc += " [\((custom as? NSObject)?.description ?? "custom")]"
           }
        
        return "[\(prefix(from: logLevel))] \(message)\(contextDesc)\n"
       }
}
