import Foundation

// MARK: - ChapterDescription extensions
extension VLCMediaPlayer.ChapterDescription {
      @objc public var timeOffset: VLCTime {
          let offset = libvlc_chapter_description_get_time_offset(chapterDescription)
          return VLCTime.timeWithNumber(offset)
          }
      @objc public var durationTime: VLCTime {
          let duration = libvlc_chapter_description_get_duration(chapterDescription)
          return VLCTime.timeWithNumber(duration)
          }
      @objc public func setCurrent() {
          libvlc_media_player_set_chapter(libVLCMediaPlayer, chapterIndex)
          }
}

// MARK: - TitleDescription extensions
extension VLCMediaPlayer.TitleDescription {
      @objc public var durationTime: VLCTime {
          let duration = libvlc_title_description_get_duration(titleDescription)
          return VLCTime.timeWithNumber(duration)
          }
      @objc public var chapterDescriptions: [VLCMediaPlayer.ChapterDescription] {
          var chapters: [VLCMediaPlayer.ChapterDescription] = []
          let count = libvlc_title_description_get_chapter_count(titleDescription)
          for i in 0..<count {
              if let ch = libvlc_title_description_get_chapter(titleDescription, i) {
                  chapters.append(VLCMediaPlayer.ChapterDescription(
                      mediaPlayer: VLCMediaPlayer(),
                      titleIndex: titleIndex,
                      chapterDescription: ch,
                      chapterIndex: i
                  ))
              }
          }
          return chapters
          }
      @objc public func setCurrent() {
          libvlc_media_player_set_title(libVLCMediaPlayer, titleIndex, 0)
          }
      @objc public func navigateActivate() {
          navigate(with: .activate)
          }
      @objc public func navigateUp() {
          navigate(with: .up)
          }
      @objc public func navigateDown() {
          navigate(with: .down)
          }
      @objc public func navigateLeft() {
          navigate(with: .left)
          }
      @objc public func navigateRight() {
          navigate(with: .right)
          }
      @objc public func navigatePopup() {
          navigate(with: .popup)
          }
      private func navigate(with action: VLCMediaPlaybackNavigationAction) {
          libvlc_title_description_navigate(titleDescription, action.rawValue)
          }
}
