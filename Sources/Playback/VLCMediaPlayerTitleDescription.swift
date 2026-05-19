import Foundation

// MARK: - ChapterDescription extensions
extension VLCMediaPlayer.ChapterDescription {
     @objc var timeOffset: VLCTime {
        let offset = libvlc_chapter_description_get_time_offset(self)
        return VLCTime.timeWithNumber(offset)
     }
     @objc var durationTime: VLCTime {
        let duration = libvlc_chapter_description_get_duration(self)
        return VLCTime.timeWithNumber(duration)
     }
     @objc func setCurrent() {
        mediaPlayer?.setCurrentChapter(chapterIndex)
     }
}

// MARK: - TitleDescription extensions
extension VLCMediaPlayer.TitleDescription {
     @objc var durationTime: VLCTime {
        let duration = libvlc_title_description_get_duration(self)
        return VLCTime.timeWithNumber(duration)
     }
     @objc var chapterDescriptions: [VLCMediaPlayer.ChapterDescription] {
        var chapters: [VLCMediaPlayer.ChapterDescription] = []
        let count = libvlc_title_description_get_chapter_count(self)
        for i in 0..<count {
            let ch = libvlc_title_description_get_chapter(self, i)
            if let ch = ch {
                chapters.append(
                    VLCMediaPlayer.ChapterDescription(
                        mediaPlayer: mediaPlayer,
                        titleIndex: titleIndex,
                        chapterDescription: ch,
                        chapterIndex: i
                    )
                )
            }
        }
        return chapters
     }
     @objc func setCurrent() {
        mediaPlayer?.setCurrentTitle(titleIndex)
     }
     @objc func navigateActivate() {
        libvlc_title_description_navigate(self, libvlc_navigation_action_activate)
     }
     @objc func navigateUp() {
        libvlc_title_description_navigate(self, libvlc_navigation_action_up)
     }
     @objc func navigateDown() {
        libvlc_title_description_navigate(self, libvlc_navigation_action_down)
     }
     @objc func navigateLeft() {
        libvlc_title_description_navigate(self, libvlc_navigation_action_left)
     }
     @objc func navigateRight() {
        libvlc_title_description_navigate(self, libvlc_navigation_action_right)
     }
     @objc func navigatePopup() {
        libvlc_title_description_navigate(self, libvlc_navigation_action_right)
     }
}
