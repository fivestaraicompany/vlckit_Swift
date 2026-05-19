import Foundation

// Meta key names for extra metadata
public enum VLCMediaMetaDataExtraKey: String {
    case composer = "COMPOSER"
    case description = "DESCRIPTION"
    case location = "LOCATION"
    case genre = "GENRE"
    case album = "ALBUM"
    case trackNumber = "TRACKNUM"
    case date = "DATE"
    case setting = "SETTING"
    case url = "URL"
    case language = "LANGUAGE"
    case nowPlaying = "NOWPLAYING"
    case publisher = "PUBLISHER"
    case encodedBy = "ENCODEDBY"
    case artworkURL = "ARTWORKURL"
    case trackID = "TRACKID"
    case trackTotal = "TRACKTOTAL"
    case director = "DIRECTOR"
    case season = "SEASON"
    case episode = "EPISODE"
    case showName = "SHOWNAME"
    case actors = "ACTORS"
    case albumArtist = "ALBUMARTIST"
    case discNumber = "DISCNUMBER"
    case discTotal = "DISCTOTAL"
}

public extension VLCMedia.MetaData {
     @objc func extraValue(forKey key: String) -> String? {
         return extraValue(forKey: key)
       }
    
     @objc func setExtraValue(_ value: String?, forKey key: String) {
         setExtraValue(value, forKey: key)
       }
    
     @objc func prefetch() {
         prefetch()
       }
    
     @objc func clearCache() {
         clearCache()
       }
}
