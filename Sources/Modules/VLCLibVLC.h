#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

// ============================
// C Type Definitions
// ============================
typedef struct libvlc_media_player_t libvlc_media_player_t;
typedef struct libvlc_media_discoverer_t libvlc_media_discoverer_t;
typedef struct libvlc_renderer_item_t libvlc_renderer_item_t;
typedef struct lib_rd_description_t lib_rd_description_t;
typedef struct libvlc_media_discoverer_description_t libvlc_media_discoverer_description_t;
typedef struct libvlc_video_picture_t libvlc_video_picture_t;
typedef struct libvlc_video_picture_planes_t libvlc_video_picture_planes_t;
typedef struct libvlc_media_tracklist_t libvlc_media_tracklist_t;
typedef struct libvlc_title_description_t libvlc_title_description_t;
typedef struct libvlc_chapter_description_t libvlc_chapter_description_t;
typedef struct libvlc_media_player_time_point_t libvlc_media_player_time_point_t;

// Core
// ============================
extern const char * libvlc_get_version(void);
extern const char * libvlc_get_compiler(void);
extern const char * libvlc_get_changeset(void);
extern int64_t libvlc_clock(void);
extern int64_t libvlc_delay(int64_t ts);
extern const char * libvlc_errmsg(void);
extern void libvlc_printerr(const char *msg);
extern void libvlc_clearerr(void);

// ============================
// Library instance
// ============================
extern void * libvlc_new(int argc, const char *const *argv);
extern void libvlc_release(void *instance);
extern void libvlc_retain(void *instance);
extern void libvlc_set_user_agent(void *instance, const char *name, const char *http_user_agent);
extern void libvlc_set_app_id(void *instance, const char *id, const char *version, const char *icon_name);

// ============================
// Log
// ============================
extern void libvlc_log_set(void *instance, void (*callback)(void *, int, const void *, const char *, va_list), void *userdata);
extern void libvlc_log_unset(void *instance);
extern int libvlc_log_set_level(void *instance, int level);

// ============================
// Media
// ============================
extern void * libvlc_media_new_path(void *instance, const char *path);
extern void * libvlc_media_new_url(void *instance, const char *uri);
extern void libvlc_media_release(void *media);
extern void libvlc_media_retain(void *media);
extern const char * libvlc_media_get_uri(void *media);
extern int libvlc_media_get_meta(void *media, int meta, char *buffer);
extern int libvlc_media_set_meta(void *media, int meta, const char *value);
extern char * libvlc_media_get_extra_meta(void *media, const char *key);
extern int libvlc_media_set_extra_meta(void *media, const char *key, const char *value);
extern int libvlc_media_get_state(void *media);
extern int64_t libvlc_media_get_duration(void *media);
extern int libvlc_media_parse(void *media);
extern int libvlc_media_parse_with_options(void *media, int options, int depth);
extern int libvlc_media_is_parsed(void *media);
extern int libvlc_media_get_parsed_status(void *media);
extern void libvlc_media_add_option(void *media, const char *option);
extern void libvlc_media_add_option_flag(void *media, const char *option, unsigned flags);
extern void * libvlc_media_subitems(void *media);
extern int libvlc_media_slaves_add(void *media, const char *uri, int type, int priority);

// ============================
// Media list
// ============================
extern void * libvlc_media_list_new(void *instance);
extern void libvlc_media_list_release(void *ml);
extern void libvlc_media_list_retain(void *ml);
extern int libvlc_media_list_add_media(void *ml, void *md);
extern int libvlc_media_list_insert_media(void *ml, void *md, int index);
extern int libvlc_media_list_remove_index(void *ml, int index);
extern int libvlc_media_list_count(void *ml);
extern void * libvlc_media_list_item_at_index(void *ml, int index);
extern int libvlc_media_list_index_of_item(void *ml, void *md);
extern int libvlc_media_list_is_readonly(void *ml);
extern void * libvlc_media_list_event_manager(void *ml);

// ============================
// Media list player
// ============================
extern void * libvlc_media_list_player_new(void *instance);
extern void libvlc_media_list_player_release(void *mlp);
extern void libvlc_media_list_player_retain(void *mlp);
extern void * libvlc_media_list_player_media_player(void *mlp);
extern int libvlc_media_list_player_set_media_list(void *mlp, void *ml);
extern int libvlc_media_list_player_play(void *mlp);
extern int libvlc_media_list_player_pause(void *mlp, int pause);
extern int libvlc_media_list_player_is_playing(void *mlp);
extern int libvlc_media_list_player_stop(void *mlp);
extern int libvlc_media_list_player_play_item(void *mlp, void *md);
extern int libvlc_media_list_player_play_item_at_index(void *mlp, int index);
extern int libvlc_media_list_player_next(void *mlp);
extern int libvlc_media_list_player_previous(void *mlp);
extern int libvlc_media_list_player_set_pause(void *mlp, int pause);
extern int libvlc_media_list_player_get_playback_mode(void *mlp);
extern int libvlc_media_list_player_set_playback_mode(void *mlp, int mode);

// ============================
// Media player
// ============================
extern void * libvlc_media_player_new_from_media(void *instance, void *md);
extern void libvlc_media_player_release(void *mp);
extern void libvlc_media_player_retain(void *mp);
extern int libvlc_media_player_is_playing(void *mp);
extern int libvlc_media_player_can_pause(void *mp);
extern int libvlc_media_player_play(void *mp);
extern int libvlc_media_player_pause(void *mp);
extern int libvlc_media_player_stop(void *mp);
extern int libvlc_media_player_set_pause(void *mp, int play);
extern int libvlc_media_player_next_frame(void *mp);
extern int libvlc_media_player_previous_frame(void *mp);
extern int libvlc_media_player_has_next_item(void *mp);
extern int libvlc_media_player_has_previous_item(void *mp);
extern void libvlc_media_player_set_media(void *mp, void *md);
extern void * libvlc_media_player_get_media(void *mp);
extern double libvlc_media_player_get_position(void *mp);
extern void libvlc_media_player_set_position(void *mp, double pos);
extern int64_t libvlc_media_player_get_time(void *mp);
extern void libvlc_media_player_set_time(void *mp, int64_t time);
extern int64_t libvlc_media_player_get_length(void *mp);
extern int libvlc_media_player_get_state(void *mp);
extern double libvlc_media_player_get_fps(void *mp);
extern int libvlc_media_player_will_play(void *mp);
extern int libvlc_media_player_set_master_volume(void *mp, int volume);
extern int libvlc_media_player_get_master_volume(void *mp);
extern int libvlc_audio_set_volume(void *mp, int volume);
extern int libvlc_audio_get_volume(void *mp);
extern int libvlc_audio_set_mute(void *mp, int mute);
extern int libvlc_audio_get_mute(void *mp);
extern void libvlc_media_player_set_subtitle_file(void *mp, const char *file);

// ============================
// Video snapshot
// ============================
extern int libvlc_media_player_take_snapshot(void *mp, unsigned num, const char *path, unsigned width, unsigned height);

// ============================
// Video adjust (filters)
// ============================
extern int libvlc_video_set_adjust_int(void *mp, int config, int value);
extern int libvlc_video_set_adjust_float(void *mp, int config, float value);
extern int libvlc_video_get_deinterlace(void *mp);
extern int libvlc_video_set_deinterlace(void *mp, int mode);

// ============================
// Audio output devices
// ============================
extern char * libvlc_audio_output_device_get(void *mp, const char *aout, const char *device);
extern int libvlc_audio_output_device_set(void *mp, const char *aout, const char *device);
extern int libvlc_audio_output_device_count(void *mp, const char *aout);
extern char ** libvlc_audio_output_device_list_get(void *mp, char *** names);
extern void libvlc_audio_output_device_list_release(char **devices, char *names);

// ============================
// Audio equalizer
// ============================
extern void * libvlc_audio_equalizer_new(void);
extern void * libvlc_audio_equalizer_new_from_preset(unsigned index);
extern void libvlc_audio_equalizer_release(void *equalizer);
extern unsigned libvlc_audio_equalizer_get_preset_count(void);
extern const char * libvlc_audio_equalizer_get_preset_name(unsigned index);
extern unsigned libvlc_audio_equalizer_get_band_count(void);
extern float libvlc_audio_equalizer_get_band_frequency(unsigned index);
extern int libvlc_audio_equalizer_set_preamp(void *equalizer, float preamp);
extern float libvlc_audio_equalizer_get_preamp(void *equalizer);
extern int libvlc_audio_equalizer_set_amp_at_index(void *equalizer, float amp, unsigned index);
extern float libvlc_audio_equalizer_get_amp_at_index(void *equalizer, unsigned index);
extern int libvlc_audio_equalizer_set_post_amp_at_index(void *equalizer, float amp, unsigned index);
extern float libvlc_audio_equalizer_get_post_amp_at_index(void *equalizer, unsigned index);

// ============================
// Renderer discoverer
// ============================
typedef struct libvlc_renderer_discoverer_t libvlc_renderer_discoverer_t;
typedef struct lib_rd_description_t {
    char *psz_name;
    char *psz_longname;
} lib_rd_description_t;

extern libvlc_renderer_discoverer_t * libvlc_renderer_discoverer_new(void *instance, const char *name);
extern void libvlc_renderer_discoverer_release(libvlc_renderer_discoverer_t *rd);
extern int libvlc_renderer_discoverer_start(libvlc_renderer_discoverer_t *rd);
extern void libvlc_renderer_discoverer_stop(libvlc_renderer_discoverer_t *rd);
extern const char * libvlc_renderer_discoverer_name(libvlc_renderer_discoverer_t *rd);
extern const char * libvlc_renderer_discoverer_long_name(libvlc_renderer_discoverer_t *rd);
extern libvlc_renderer_discoverer_t * libvlc_renderer_discoverer_next(libvlc_renderer_discoverer_t *rd);
extern void * libvlc_renderer_discoverer_event_manager(libvlc_renderer_discoverer_t *rd);
extern size_t libvlc_renderer_discoverer_list_get(void *instance, lib_rd_description_t *** services);
extern void libvlc_renderer_discoverer_list_release(lib_rd_description_t ** services, size_t n_services);

// ============================
// Renderer item
// ============================
typedef struct libvlc_renderer_item_t libvlc_renderer_item_t;
extern libvlc_renderer_item_t * libvlc_renderer_item_hold(libvlc_renderer_item_t *item);
extern void libvlc_renderer_item_release(libvlc_renderer_item_t *item);
extern const char * libvlc_renderer_item_name(libvlc_renderer_item_t *item);
extern const char * libvlc_renderer_item_type(libvlc_renderer_item_t *item);
extern const char * libvlc_renderer_item_icon_uri(libvlc_renderer_item_t *item);
extern unsigned libvlc_renderer_item_flags(libvlc_renderer_item_t *item);
extern libvlc_renderer_item_t * libvlc_renderer_item_next(libvlc_renderer_item_t *item);

// ============================
// Media discoverer
// ============================
typedef struct libvlc_media_discoverer_description_t {
    char *psz_name;
    char *psz_longname;
    int i_cat;
} libvlc_media_discoverer_description_t;
typedef int libvlc_media_discoverer_category_t;
extern libvlc_media_discoverer_t * libvlc_media_discoverer_new(void *instance, const char *name);
extern void libvlc_media_discoverer_release(libvlc_media_discoverer_t *md);
extern int libvlc_media_discoverer_start(libvlc_media_discoverer_t *md);
extern void libvlc_media_discoverer_stop(libvlc_media_discoverer_t *md);
extern int libvlc_media_discoverer_is_running(libvlc_media_discoverer_t *md);
extern void * libvlc_media_discoverer_media_list(libvlc_media_discoverer_t *md);
extern ssize_t libvlc_media_discoverer_list_get(void *instance, libvlc_media_discoverer_category_t cat, libvlc_media_discoverer_description_t *** discoverers);
extern void libvlc_media_discoverer_list_release(libvlc_media_discoverer_description_t **discoverers, ssize_t n_discoverers);

// ============================
// Dialog
// ============================
typedef struct libvlc_dialog_id_t libvlc_dialog_id_t;
typedef void (*libvlc_dialog_login_callback)(void *data, libvlc_dialog_id_t *id, const char *username, const char *password, int store);
typedef void (*libvlc_dialog_action_callback)(void *data, libvlc_dialog_id_t *id, const char *action_id);
typedef void (*libvlc_dialog_cancel_callback)(void *data, libvlc_dialog_id_t *id);
typedef void (*libvlc_dialog_progress_callback)(void *data, libvlc_dialog_id_t *id, int indeterminate, float position, const char *message);
typedef void (*libvlc_dialog_error_callback)(void *data, const char *title, const char *text);
extern void libvlc_dialog_set_callbacks(void *instance, void *cbs, void *data);
extern void libvlc_dialog_set_error_callback(void *instance, libvlc_dialog_error_callback callback, void *data);
extern void libvlc_dialog_dismiss(libvlc_dialog_id_t *id);
extern int libvlc_dialog_post_action(libvlc_dialog_id_t *id, const char *action_id);
extern int libvlc_dialog_post_login(libvlc_dialog_id_t *id, const char *username, const char *password, int store);
extern void libvlc_dialog_set_progress(libvlc_dialog_id_t *id, int indeterminate, float position, const char *message);

// ============================
// Track selection
// ============================
typedef struct libvlc_media_tracklist_t libvlc_media_tracklist_t;
extern libvlc_media_tracklist_t * libvlc_media_player_get_tracklist(void *mp, int type, int selected);
extern size_t libvlc_media_tracklist_count(libvlc_media_tracklist_t *list);
extern void * libvlc_media_tracklist_at(libvlc_media_tracklist_t *list, size_t index);
extern void libvlc_media_tracklist_delete(libvlc_media_tracklist_t *list);
extern int libvlc_media_player_select_track(void *mp, void *track);
extern int libvlc_media_player_select_tracks_by_ids(void *mp, int type, const char *ids);
extern int libvlc_media_player_unselect_track_type(void *mp, int type);
extern int libvlc_media_player_set_renderer_instance(void *mp, void *renderer);

// ============================
// Title / Chapter / Navigation
// ============================
typedef struct libvlc_chapter_description_t libvlc_chapter_description_t;
extern int libvlc_media_player_get_title_count(void *mp);
extern int libvlc_media_player_get_chapter_count(void *mp, int title);
extern int libvlc_media_player_set_title(void *mp, int title, int chapter);
extern int libvlc_media_player_set_chapter(void *mp, int chapter);
extern int libvlc_media_player_get_title(void *mp);
extern int libvlc_media_player_get_chapter(void *mp);
extern libvlc_title_description_t ** libvlc_media_player_get_title_description(void *mp);
extern libvlc_chapter_description_t ** libvlc_media_player_get_chapter_description(void *mp, int title);
extern void libvlc_title_description_release(libvlc_title_description_t **descs, int count);
extern void libvlc_chapter_description_release(libvlc_chapter_description_t **descs, int count);
extern int64_t libvlc_chapter_description_get_time_offset(libvlc_chapter_description_t *desc);
extern int64_t libvlc_chapter_description_get_duration(libvlc_chapter_description_t *desc);
extern const char * libvlc_chapter_description_get_name(libvlc_chapter_description_t *desc);
extern void libvlc_title_description_navigate(libvlc_title_description_t *desc, unsigned action);
extern int libvlc_video_update_viewpoint(void *mp, float yaw, float pitch, float roll, float fov, int absolute);
extern int libvlc_title_description_get_chapter_count(void *td);
extern void * libvlc_title_description_get_chapter(void *td, int chapter);
extern int64_t libvlc_title_description_get_duration(void *td);
extern int libvlc_media_player_update_viewpoint(void *mp, float yaw, float pitch, float roll, float fov, int absolute);



// ============================
// Free / Utility
// ============================
extern void libvlc_free(void *ptr);

// ============================
// Constants (for Swift bridging)
// ============================
// Playback mode
extern int libvlc_playback_mode_default;
extern int libvlc_playback_mode_repeat;
extern int libvlc_playback_mode_loop;

// Adjust filter constants
extern int libvlc_adjust_Enable;
extern int libvlc_adjust_Contrast;
extern int libvlc_adjust_Brightness;
extern int libvlc_adjust_Hue;
extern int libvlc_adjust_Saturation;
extern int libvlc_adjust_Gamma;

// Meta constants
extern int libvlc_meta_Title;
extern int libvlc_meta_Artist;
extern int libvlc_meta_Genre;
extern int libvlc_meta_Copyright;
extern int libvlc_meta_Album;
extern int libvlc_meta_TrackNumber;
extern int libvlc_meta_Description;
extern int libvlc_meta_Rating;
extern int libvlc_meta_Date;
extern int libvlc_meta_Setting;
extern int libvlc_meta_URL;
extern int libvlc_meta_Language;
extern int libvlc_meta_NowPlaying;
extern int libvlc_meta_Publisher;
extern int libvlc_meta_EncodedBy;
extern int libvlc_meta_ArtworkURL;
extern int libvlc_meta_TrackID;
extern int libvlc_meta_TrackTotal;
extern int libvlc_meta_Director;
extern int libvlc_meta_Season;
extern int libvlc_meta_Episode;
extern int libvlc_meta_ShowName;
extern int libvlc_meta_Actors;
extern int libvlc_meta_AlbumArtist;
extern int libvlc_meta_DiscNumber;
extern int libvlc_meta_DiscTotal;

// Track types
extern int libvlc_track_audio;
extern int libvlc_track_video;
extern int libvlc_track_text;

// State constants
extern int libvlc_state_opening;
extern int libvlc_state_buffering;
extern int libvlc_state_playing;
extern int libvlc_state_paused;
extern int libvlc_state_stopped;
extern int libvlc_state_ended;
extern int libvlc_state_error;

// Deinterlace mode
extern int libvlc_deinterlace_auto;
extern int libvlc_deinterlace_on;
extern int libvlc_deinterlace_off;

// Parse options
extern int libvlc_parse_local;
extern int libvlc_parse_network;
extern int libvlc_parse_local_and_network;
extern int libvlc_fetch_local;
extern int libvlc_fetch_network;
extern int libvlc_fetch_local_and_network;
extern int libvlc_parse_depth_max;

// Media state
extern int libvlc_media_state_playing;
extern int libvlc_media_state_opening;
extern int libvlc_media_state_buffering;
extern int libvlc_media_state_paused;
extern int libvlc_media_state_stopped;
extern int libvlc_media_state_ended;
extern int libvlc_media_state_error;
extern int libvlc_media_state_unknown;

// Renderers
extern int libvlc_renderer_plays_audio;
extern int libvlc_renderer_plays_video;

// Dialog question types
extern int libvlc_dialog_question_normal;
extern int libvlc_dialog_question_warning;
extern int libvlc_dialog_question_critical;

// Navigation actions
extern int libvlc_navigation_action_activate;
extern int libvlc_navigation_action_up;
extern int libvlc_navigation_action_down;
extern int libvlc_navigation_action_left;
extern int libvlc_navigation_action_right;
