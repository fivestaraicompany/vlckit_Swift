import Foundation

// MARK: - Default constants
public extension VLCStreamOutput {
          static var defaultRTSP: String {
              VLCDefaultStreamOutputRTSP
         }
          static var defaultRTP: String {
              VLCDefaultStreamOutputRTP
         }
}

// MARK: - Convenience factories
public extension VLCStreamOutput {
          static func rtpBroadcast(withSAPAnnounce announceName: String) -> VLCStreamOutput {
              VLCStreamOutput(optionDictionary: [
                   "rtpOptions": [
                        "muxer": "ts", "access": "file", "sdp": "sdp",
                        "sap": "sap", "name": announceName, "destination": "239.255.1.1"
                   ]
               ]) as! VLCStreamOutput
         }
      
          static func rtpBroadcast() -> VLCStreamOutput {
              rtpBroadcast(withSAPAnnounce: "Helloworld!")
         }
      
          static func ipod(withFilePath filePath: String) -> VLCStreamOutput {
              VLCStreamOutput(optionDictionary: [
                   "transcodingOptions": [
                        "videoCodec": "h264", "videoBitrate": "1024",
                        "audioCodec": "mp3", "audioBitrate": "128",
                        "channels": "2", "width": "640", "height": "480", "audio-sync": "Yes"
                   ],
                   "outputOptions": [
                        "muxer": "mp4", "access": "file",
                        "destination": NSURL(fileURLWithPath: filePath).absoluteString
                   ]
               ]) as! VLCStreamOutput
         }
      
          static func mpeg4(withFilePath filePath: String) -> VLCStreamOutput {
              VLCStreamOutput(optionDictionary: [
                   "transcodingOptions": [
                        "videoCodec": "mp4v", "videoBitrate": "1024",
                        "audioCodec": "mp4a", "audioBitrate": "192"
                   ],
                   "outputOptions": [
                        "muxer": "mp4", "access": "file", "destination": filePath
                   ]
               ]) as! VLCStreamOutput
         }
      
          static func mpeg2(withFilePath filePath: String) -> VLCStreamOutput {
              VLCStreamOutput(optionDictionary: [
                   "transcodingOptions": [
                        "videoCodec": "mp2v", "videoBitrate": "1024",
                        "audioCodec": "mpga", "audioBitrate": "128", "audio-sync": "Yes"
                   ],
                   "outputOptions": [
                        "muxer": "ps", "access": "file", "destination": filePath
                   ]
               ]) as! VLCStreamOutput
         }
}

// MARK: - Represented options
extension VLCStreamOutput {
          func representedLibVLCOptions() -> String {
              guard let opts = options as? [String: Any] else { return "" }
              var optionsAsArray: [String] = []
              
              if let transcodingOpts = opts["transcodingOptions"] as? [String: String] {
                  var subOpts: [String] = []
                  if let vc = transcodingOpts["videoEncoder"] { subOpts.append("venc=\(vc)") }
                  if let vc = transcodingOpts["videoCodec"] { subOpts.append("vcodec=\(vc)") }
                  if let vb = transcodingOpts["videoBitrate"] { subOpts.append("vb=\(vb)") }
                  if let w = transcodingOpts["width"] { subOpts.append("width=\(w)") }
                  if let h = transcodingOpts["height"] { subOpts.append("height=\(h)") }
                  if let ch = transcodingOpts["canvasHeight"] { subOpts.append("canvas-height=\(ch)") }
                  if let ac = transcodingOpts["audioCodec"] { subOpts.append("acodec=\(ac)") }
                  if let ab = transcodingOpts["audioBitrate"] { subOpts.append("ab=\(ab)") }
                  if let ch = transcodingOpts["channels"] { subOpts.append("channels=\(ch)") }
                  if transcodingOpts.keys.contains("audio-sync") { subOpts.append("audioSync") }
                  if let sc = transcodingOpts["subtitleCodec"] { subOpts.append("scodec=\(sc)") }
                  if let se = transcodingOpts["subtitleEncoder"] { subOpts.append("senc=\(se)") }
                  if transcodingOpts.keys.contains("subtitle-overlay") { subOpts.append("soverlay") }
                  optionsAsArray.append("#transcode{\(subOpts.joined(separator: ","))}")
               }
              
              if let outputOpts = opts["outputOptions"] as? [String: String] {
                  var subOpts: [String] = []
                  if let m = outputOpts["muxer"] { subOpts.append("mux=\(m)") }
                  if let d = outputOpts["destination"] {
                      subOpts.append("dst=\"\(d.replacingOccurrences(of: "\"", with: "\\\""))\"")
                   }
                  if let a = outputOpts["access"] { subOpts.append("access=\(a)") }
                  let std = "#std{\(subOpts.joined(separator: ","))}"
                  optionsAsArray.append(std)
               }
              
              if let rtpOpts = opts["rtpOptions"] as? [String: String] {
                  var subOpts: [String] = []
                  if let m = rtpOpts["muxer"] { subOpts.append("muxer=\(m)") }
                  if let d = rtpOpts["destination"] { subOpts.append("dst=\(d)") }
                  if let s = rtpOpts["sdp"] { subOpts.append("sdp=\(s)") }
                  if rtpOpts.keys.contains("sap") { subOpts.append("sap") }
                  if let n = rtpOpts["name"] { subOpts.append("name=\"\(n)\"") }
                  let rtp = "#rtp{\(subOpts.joined(separator: ","))}"
                  optionsAsArray.append(rtp)
               }
              
              return optionsAsArray.joined(separator: ":")
           }
    
     private let options: [String: Any]?
      
          @objc convenience init(optionDictionary: [String: Any]) {
              self.init()
              self.options = optionDictionary
          }
}
