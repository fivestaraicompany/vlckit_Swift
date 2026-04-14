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

    public override init() {
        super.init()
        _options = nil
    }

    public init(optionDictionary dictionary: [String: Any]?) {
        super.init()
        _options = dictionary
    }

    public override var description: String {
        return representedLibVLCOptions()
    }

    public static func streamOutput(withOptionDictionary dictionary: [String: Any]?) -> VLCStreamOutput {
        return VLCStreamOutput(optionDictionary: dictionary)
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
        var subOptions: [String] = []
        var optionsAsArray: [String] = []
        let hasTranscoding = _options?["transcodingOptions"] != nil

        if let transcodingOptions = _options?["transcodingOptions"] as? [String: String] {
            if let videoEncoder = transcodingOptions["videoEncoder"] {
                subOptions.append("venc=\(videoEncoder)")
            }
            if let videoCodec = transcodingOptions["videoCodec"] {
                subOptions.append("vcodec=\(videoCodec)")
            }
            if let videoBitrate = transcodingOptions["videoBitrate"] {
                subOptions.append("vb=\(videoBitrate)")
            }
            if let width = transcodingOptions["width"] {
                subOptions.append("width=\(width)")
            }
            if let height = transcodingOptions["height"] {
                subOptions.append("height=\(height)")
            }
            if let canvasHeight = transcodingOptions["canvasHeight"] {
                subOptions.append("canvas-height=\(canvasHeight)")
            }
            if let audioCodec = transcodingOptions["audioCodec"] {
                subOptions.append("acodec=\(audioCodec)")
            }
            if let audioBitrate = transcodingOptions["audioBitrate"] {
                subOptions.append("ab=\(audioBitrate)")
            }
            if let channels = transcodingOptions["channels"] {
                subOptions.append("channels=\(channels)")
            }
            if transcodingOptions["audioSync"] != nil {
                subOptions.append("audioSync")
            }
            if let subtitleCodec = transcodingOptions["subtitleCodec"] {
                subOptions.append("scodec=\(subtitleCodec)")
            }
            if let subtitleEncoder = transcodingOptions["subtitleEncoder"] {
                subOptions.append("senc=\(subtitleEncoder)")
            }
            if transcodingOptions["subtitleOverlay"] != nil {
                subOptions.append("soverlay")
            }

            optionsAsArray.append("#transcode{\(subOptions.joined(separator: ","))}")
            subOptions.removeAll()
        }

        if let outputOptions = _options?["outputOptions"] as? [String: String] {
            if let muxer = outputOptions["muxer"] {
                subOptions.append("mux=\(muxer)")
            }
            if let destination = outputOptions["destination"] {
                subOptions.append("dst=\"\(destination.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            if let url = outputOptions["url"] {
                subOptions.append("url=\"\(url.replacingOccurrences(of: "\"", with: "\\\""))\"")
            }
            if let access = outputOptions["access"] {
                subOptions.append("access=\(access)")
            }

            let std = "#std{\(subOptions.joined(separator: ","))}"
            optionsAsArray.append(std)
            subOptions.removeAll()
        }

        if let rtpOptions = _options?["rtpOptions"] as? [String: String] {
            if let muxer = rtpOptions["muxer"] {
                subOptions.append("muxer=\(muxer)")
            }
            if let destination = rtpOptions["destination"] {
                subOptions.append("dst=\(destination)")
            }
            if let sdp = rtpOptions["sdp"] {
                subOptions.append("sdp=\(sdp)")
            }
            if rtpOptions["sap"] != nil {
                subOptions.append("sap")
            }
            if let name = rtpOptions["name"] {
                subOptions.append("name=\"\(name)\"")
            }

            let rtp = "#rtp{\(subOptions.joined(separator: ","))}"
            optionsAsArray.append(rtp)
            subOptions.removeAll()
        }

        return optionsAsArray.joined(separator: ":")
    }
}
