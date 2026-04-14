//
//  VLCStreamOutput.swift
//  VLCKit
//
//  VLCStreamOutput - Stream output for VLC
//

import Foundation

/**
 VLCStreamOutput - Stream output for VLC
 */
public class VLCStreamOutput: NSObject {

    private var _options: [String: Any]?

     /**
     Create a new stream output
      */
    public override init() {
        super.init()
          _options = nil
      }

     /**
     Create a new stream output with options

       - Parameter dictionary: The options dictionary
       - Returns: A new stream output instance
       */
    public convenience init?(optionDictionary dictionary: [String: Any]?) {
        self.init()
          _options = dictionary?.mutableCopy() as? [String: Any]
      }

    public override var description: String {
        return representedLibVLCOptions()
      }

    public static func streamOutput(withOptionDictionary dictionary: [String: Any]?) -> VLCStreamOutput {
        return VLCStreamOutput(optionDictionary: dictionary) ?? VLCStreamOutput()
      }

    public static func rtpBroadcastStreamOutput(withSAPAnnounce announceName: String) -> VLCStreamOutput {
        return streamOutput(withOptionDictionary: [
            "rtpOptions": [
                "muxer": "ts",
                "access": "file",
                "sdp": "sdp",
                "sap": "sap",
                "name": announceName,
                "destination": "239.255.1.1"
            ]
        ])
      }

    public static func rtpBroadcastStreamOutput() -> VLCStreamOutput {
        return rtpBroadcastStreamOutput(withSAPAnnounce: "Helloworld!")
      }

    public static func ipodStreamOutput(withFilePath filePath: String) -> VLCStreamOutput {
        return streamOutput(withOptionDictionary: [
            "transcodingOptions": [
                "videoCodec": "h264",
                "videoBitrate": "1024",
                "audioCodec": "mp3",
                "audioBitrate": "128",
                "channels": "2",
                "width": "640",
                "height": "480",
                "audio-sync": "Yes"
            ],
            "outputOptions": [
                "muxer": "mp4",
                "access": "file",
                "destination": filePath
            ]
        ])
      }

    public static func mpeg4StreamOutput(withFilePath filePath: String) -> VLCStreamOutput {
        return streamOutput(withOptionDictionary: [
            "transcodingOptions": [
                "videoCodec": "mp4v",
                "videoBitrate": "1024",
                "audioCodec": "mp4a",
                "audioBitrate": "192"
            ],
            "outputOptions": [
                "muxer": "mp4",
                "access": "file",
                "destination": filePath
            ]
        ])
      }

    public static func streamOutput(withFilePath filePath: String) -> VLCStreamOutput {
        return streamOutput(withOptionDictionary: [
            "outputOptions": [
                "muxer": "ps",
                "access": "file",
                "destination": filePath
            ]
        ])
      }

    public static func mpeg2StreamOutput(withFilePath filePath: String) -> VLCStreamOutput {
        return streamOutput(withOptionDictionary: [
            "transcodingOptions": [
                "videoCodec": "mp2v",
                "videoBitrate": "1024",
                "audioCodec": "mpga",
                "audioBitrate": "128",
                "audio-sync": "Yes"
            ],
            "outputOptions": [
                "muxer": "ps",
                "access": "file",
                "destination": filePath
            ]
        ])
      }

    public func representedLibVLCOptions() -> String {
        var representedOptions = ""
        var subOptions: [String] = []
        var optionsAsArray: [String] = []

        if let transcodingOptions = _options?["transcodingOptions"] as? [String: String] {
            let videoCodec = transcodingOptions["videoCodec"]
            let audioCodec = transcodingOptions["audioCodec"]
            let subtitleCodec = transcodingOptions["subtitleCodec"]
            let videoBitrate = transcodingOptions["videoBitrate"]
            let audioBitrate = transcodingOptions["audioBitrate"]
            let channels = transcodingOptions["channels"]
            let height = transcodingOptions["height"]
            let canvasHeight = transcodingOptions["canvasHeight"]
            let width = transcodingOptions["width"]
            let audioSync = transcodingOptions["audioSync"]
            let videoEncoder = transcodingOptions["videoEncoder"]
            let subtitleEncoder = transcodingOptions["subtitleEncoder"]
            let subtitleOverlay = transcodingOptions["subtitleOverlay"]

            if let videoEncoder = videoEncoder {
                subOptions.append("venc=\(videoEncoder)")
              }
            if let videoCodec = videoCodec {
                subOptions.append("vcodec=\(videoCodec)")
              }
            if let videoBitrate = videoBitrate {
                subOptions.append("vb=\(videoBitrate)")
              }
            if let width = width {
                subOptions.append("width=\(width)")
              }
            if let height = height {
                subOptions.append("height=\(height)")
              }
            if let canvasHeight = canvasHeight {
                subOptions.append("canvas-height=\(canvasHeight)")
              }
            if let audioCodec = audioCodec {
                subOptions.append("acodec=\(audioCodec)")
              }
            if let audioBitrate = audioBitrate {
                subOptions.append("ab=\(audioBitrate)")
              }
            if let channels = channels {
                subOptions.append("channels=\(channels)")
              }
            if audioSync != nil {
                subOptions.append("audioSync")
              }
            if let subtitleCodec = subtitleCodec {
                subOptions.append("scodec=\(subtitleCodec)")
              }
            if let subtitleEncoder = subtitleEncoder {
                subOptions.append("senc=\(subtitleEncoder)")
              }
            if subtitleOverlay != nil {
                subOptions.append("soverlay")
              }

            optionsAsArray.append("#transcode{\(subOptions.joined(separator: ","))}")
            subOptions.removeAll()
          }

        if let outputOptions = _options?["outputOptions"] as? [String: String] {
            let muxer = outputOptions["muxer"]
            let destination = outputOptions["destination"]
            let url = outputOptions["url"]
            let access = outputOptions["access"]

            if let muxer = muxer {
                subOptions.append("mux=\(muxer)")
              }
            if let destination = destination {
                subOptions.append("dst=\"\(destination.replacingOccurrences(of: "\"", with: "\\\""))\"")
              }
            if let url = url {
                subOptions.append("url=\"\(url.replacingOccurrences(of: "\"", with: "\\\""))\"")
              }
            if let access = access {
                subOptions.append("access=\(access)")
              }

            let std = "#std{\(subOptions.joined(separator: ","))}"

            if transcodingOptions == nil {
                representedOptions = std
              }

            optionsAsArray.append(std)
            subOptions.removeAll()
          }

        if let rtpOptions = _options?["rtpOptions"] as? [String: String] {
            let muxer = rtpOptions["muxer"]
            let destination = rtpOptions["destination"]
            let sdp = rtpOptions["sdp"]
            let name = rtpOptions["name"]
            let sap = rtpOptions["sap"]

            if let muxer = muxer {
                subOptions.append("muxer=\(muxer)")
              }
            if let destination = destination {
                subOptions.append("dst=\(destination)")
              }
            if let sdp = sdp {
                subOptions.append("sdp=\(sdp)")
              }
            if let sap = sap {
                subOptions.append("sap")
              }
            if let name = name {
                subOptions.append("name=\"\(name)\"")
              }

            let rtp = "#rtp{\(subOptions.joined(separator: ","))}"

            if transcodingOptions == nil {
                representedOptions = rtp
              }

            optionsAsArray.append(rtp)
            subOptions.removeAll()
          }

        representedOptions = optionsAsArray.joined(separator: ":")
        return representedOptions
      }
}
