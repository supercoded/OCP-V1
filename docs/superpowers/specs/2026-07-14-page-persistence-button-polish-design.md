# Page Persistence and Button Polish Design

## Goal

Make OCP preserve each workspace page while the user moves between sidebar tabs, restore safe UI state after app restart, and clean up desktop controls so buttons either perform the intended action or are clearly presented as informational.

## Decisions

- Use Approach A: keep all workspace pages mounted and hide inactive pages.
- Persist safe UI preferences across app restarts.
- Restore live SDR/radio session context after restart, but require the user to press Resume before reconnecting or playing audio.
- Drop signal GPS mapping. The Map may show mesh nodes, RuView targets, offline tiles, and later receiver-site metadata, but ordinary analog spectrum audio must not be presented as talker GPS.
- Audit every desktop page and fix the user-visible broken or misleading controls.

## Architecture

`App` will render a stable page slot for each workspace instead of switching a single `WorkspacePage` subtree. Each page slot gets its own error boundary and is hidden when inactive. This preserves React component state, imperative DOM state, MapLibre instances, Spectrum waterfall state, Messaging drafts, and Devices/Baofeng edits while navigating.

Restart persistence will use an app preferences store backed by Electron `userData`, following the existing JSON-store pattern used by security and online receiver preferences. The renderer will expose page preference updates through `OcpServiceContext`; the main process remains the authority for live device/session status.

Live resources must be explicit. Same-session tab switches should not close online SDR BrowserViews or disconnect local RTL. App restart should restore the last selected receiver/source and tuning fields, then show Resume rather than auto-connecting.

## Components

- `App`: own active workspace, render all workspace pages in persistent slots, and persist the last workspace.
- `OcpServiceContext`: expose app preference state plus read/update helpers.
- Main process app prefs service: load/save safe preferences in `userData`.
- Spectrum: persist selected mode, local source fields, tuning/display preferences, online filters, last receiver, and manual Resume state.
- Map: persist layer toggles, loaded offline tile file metadata, and camera. Reconnect UI to existing `mapPort` state so the map does not forget a running tile server.
- Messaging: persist active channel, destination, and draft. Fix unread badge behavior.
- Devices: persist selected device sub-tab, connection fields, RuView fields, Baofeng port/auto-connect preference, and Baofeng unsaved channel draft.
- Network/Sonar/Settings: preserve mounted state; persist only safe preferences where useful. Do not persist PIN text.

## Button Polish

Fix or clarify the known issues from the audit:

- Spectrum click-to-VFO currently moves only the overlay. It should either retune the RTL when connected or make clear it is a visual VFO selection; the preferred fix is retune-on-click with visible feedback.
- Spectrum bookmarks save modulation/bandwidth but tuning applies only frequency. Apply bandwidth to VFO state and make unsupported modulation explicit.
- Messaging unread badges should clear when a channel is viewed instead of counting all inbound messages forever.
- Map Offline Active currently stops tiles and the Offline Tiles toggle can enable without a loaded tile source. Labels and disabled states should match behavior.
- Map Center Self should use `localNodeId` when available and avoid treating the first arbitrary node as self.
- Settings Change PIN should not label the new PIN as optional when it is required.
- Firmware/docs-only areas should look informational, not like broken controls.
- Intentional placeholders such as Network routes or Sonar unsupported filters should be labeled as unavailable or hidden until backed by data.

## Data Flow

On app start, main loads persisted preferences and includes them in the renderer API. `OcpServiceContext` stores preferences above all pages, so page components can initialize from shared state and update it through debounced or explicit save calls.

During sidebar navigation, page components remain mounted. The active workspace controls visibility only. Hidden pages should not steal focus; any expensive animation/subscription should either keep running only when needed for continuity or pause when inactive without dropping state.

For restart recovery, persisted preferences repopulate page fields. Live sessions show an inactive restored state with Resume. User actions still call existing IPC handlers for connect, listen, map load, send, lock, and plugin operations.

## Error Handling

Preference load failures should fall back to defaults and not block the app. Preference save failures should surface as non-fatal status text when relevant and log in main.

If a restored SDR receiver/source is unavailable, show the stored details and a failed Resume message with external-open or reconnect options. If an offline tile path no longer exists, disable the offline layer and ask the user to reload the file.

Each persistent page slot keeps its own error boundary so a page crash can be retried without resetting unrelated pages.

## Testing

- Unit-test preference merge/default behavior where practical.
- Build the desktop app after changes.
- Run existing package tests.
- Smoke-test sidebar navigation: enter state on each page, switch away and back, verify it remains.
- Smoke-test app restart: verify safe preferences restore and SDR sessions require Resume.
- Smoke-test button fixes on Spectrum, Map, Messaging, Devices, Settings, Sonar, and Network.

## Out of Scope

- Automatic SDR audio playback after restart.
- GPS mapping of analog voice talkers.
- A full firmware flasher implementation.
- Direction finding or multi-receiver geolocation.
