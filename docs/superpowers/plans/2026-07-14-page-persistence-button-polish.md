# Page Persistence and Button Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve each OCP workspace across sidebar navigation and restart, then fix misleading or broken desktop controls.

**Architecture:** Render all workspace pages in stable hidden slots so same-session state is not lost. Add a main-process JSON preference store and renderer context helpers for restart-safe preferences. Keep live SDR/radio sessions manual on restart and make every button either functional or clearly informational.

**Tech Stack:** Electron, React, TypeScript, Electron IPC, JSON files in Electron `userData`, existing `OcpServiceContext`.

---

## File Structure

- Modify `apps/desktop/src/renderer/App.tsx`: persistent workspace slots and last-workspace persistence.
- Create `apps/desktop/src/main/services/appPreferencesStore.ts`: safe user preference JSON store.
- Modify `apps/desktop/src/main/services/ocpService.ts`: load/save preferences IPC.
- Modify `apps/desktop/src/preload.ts`: expose preference IPC.
- Modify `apps/desktop/src/renderer/contexts/OcpServiceContext.tsx`: preference state and helpers.
- Modify `apps/desktop/src/renderer/pages/SpectrumPage.tsx`: persist mode and remove tab-switch session close.
- Modify `apps/desktop/src/renderer/components/SpectrumLocalPanel.tsx`: persist local tuning/display state and fix click-to-retune/bookmark bandwidth.
- Modify `apps/desktop/src/renderer/components/OnlineReceiversPanel.tsx`: preserve same-session BrowserView, restore last receiver, add manual Resume semantics.
- Modify `apps/desktop/src/renderer/pages/MapPage.tsx`: persist layer/camera/tile state and fix Center Self/offline tile UX.
- Modify `apps/desktop/src/renderer/pages/MessagingPage.tsx`: persist draft/channel/destination and fix unread badges.
- Modify `apps/desktop/src/renderer/pages/DevicesPage.tsx` and `apps/desktop/src/renderer/components/BaofengChannelEditor.tsx`: persist tabs/forms/Baofeng draft.
- Modify `apps/desktop/src/renderer/pages/SettingsPage.tsx`, `NetworkPage.tsx`, `SonarPage.tsx`: polish misleading labels/placeholders.
- Optional tests under `apps/desktop/src/**` if an existing test harness is present; otherwise rely on build plus package tests and smoke checklist.

## Chunk 1: Persistent Workspace Slots

### Task 1: Keep workspaces mounted

**Files:**
- Modify: `apps/desktop/src/renderer/App.tsx`

- [ ] Replace `WorkspacePage` switch rendering with a static list of page slots, one per workspace.
- [ ] Wrap each page in its own `PageErrorBoundary` keyed by stable workspace id, not by active workspace.
- [ ] Hide inactive slots with CSS (`hidden`, `aria-hidden`, pointer events disabled) while keeping components mounted.
- [ ] Preserve the header/footer active label from current `active` state.
- [ ] Run `npm run build --workspace=@ocp/desktop`.
- [ ] Smoke-test switching tabs after typing in Messaging and changing Spectrum/Map controls.

### Task 2: Remove same-session Online SDR close on tab switch

**Files:**
- Modify: `apps/desktop/src/renderer/pages/SpectrumPage.tsx`
- Modify: `apps/desktop/src/renderer/components/OnlineReceiversPanel.tsx`

- [ ] Remove the effect that closes `closeOnlineSession` when leaving Spectrum online mode.
- [ ] Only close the BrowserView when the user presses Close, app shuts down, or online session is replaced.
- [ ] When Online panel is hidden, keep the session record intact.
- [ ] Verify Local RTL and Online Receiver states survive switching to Map and back.

## Chunk 2: Restart Preferences Store

### Task 3: Add main-process app preferences store

**Files:**
- Create: `apps/desktop/src/main/services/appPreferencesStore.ts`
- Modify: `apps/desktop/src/main/services/ocpService.ts`

- [ ] Define an `AppPreferences` shape with safe fields only: last workspace, per-page UI state, Spectrum source/tuning, Map layers/camera/tile file, Messaging draft/channel/destination, Devices forms/tabs, Baofeng draft/preferences.
- [ ] Implement load with defaults and save with atomic-enough JSON write to `userData/ocp-app-preferences.json`.
- [ ] Add IPC handlers: `ocp:prefs:get`, `ocp:prefs:update`, and optionally `ocp:prefs:resetPage`.
- [ ] Avoid persisting PIN fields, transient errors, and active audio/playback flags.
- [ ] Run desktop build.

### Task 4: Expose preferences to renderer

**Files:**
- Modify: `apps/desktop/src/preload.ts`
- Modify: `apps/desktop/src/renderer/contexts/OcpServiceContext.tsx`

- [ ] Add preload methods for preference get/update/reset.
- [ ] Add `preferences`, `updatePreferences`, and `updatePagePreferences` to `OcpServiceAPI`.
- [ ] Load preferences on provider mount before or alongside state load.
- [ ] Merge partial updates conservatively so one page cannot wipe another page's preferences.
- [ ] Run desktop build and lints on edited files.

## Chunk 3: Page Preference Wiring

### Task 5: Persist workspace and page tabs

**Files:**
- Modify: `apps/desktop/src/renderer/App.tsx`
- Modify: `apps/desktop/src/renderer/pages/SpectrumPage.tsx`
- Modify: `apps/desktop/src/renderer/pages/DevicesPage.tsx`

- [ ] Initialize `active` workspace from preferences.
- [ ] Save active workspace on sidebar change.
- [ ] Initialize/save Spectrum mode (`local` or `online`).
- [ ] Initialize/save Devices tab.
- [ ] Verify restart returns to the same workspace and tab without starting live sessions.

### Task 6: Persist Spectrum state and manual Resume

**Files:**
- Modify: `apps/desktop/src/renderer/components/SpectrumLocalPanel.tsx`
- Modify: `apps/desktop/src/renderer/components/OnlineReceiversPanel.tsx`

- [ ] Initialize local host, port, center frequency, gain, display toggles, and VFO bandwidth from preferences.
- [ ] Save changes when fields/toggles update.
- [ ] On connected local RTL, clicking the spectrum should retune with `setRtlFreq`; when disconnected it should update VFO and center field only.
- [ ] Apply bookmark bandwidth to VFO state when tuning; keep modulation informational unless receiver support exists.
- [ ] Restore last online receiver/source after restart with a Resume button; do not auto-open BrowserView.
- [ ] Verify tab switch preserves the live BrowserView; restart shows Resume.

### Task 7: Persist Map state and fix map controls

**Files:**
- Modify: `apps/desktop/src/renderer/pages/MapPage.tsx`
- Modify: `apps/desktop/src/renderer/components/MapControls.tsx`

- [ ] Persist layer toggles, camera center/zoom, and last tile file path.
- [ ] On restart, if tile file exists, offer Reload Tiles; do not silently start external resources unless existing app behavior requires it.
- [ ] Disable Offline Tiles toggle until tiles are loaded, or make it clearly a layer visibility toggle.
- [ ] Change active tile button label from misleading "Offline Active" to "Stop Offline Tiles".
- [ ] Center Self using `service.state.localNodeId` first, then a clearly labeled fallback.
- [ ] Verify map camera/layers survive tab switching and safe restart behavior works.

### Task 8: Persist Messaging and Devices state

**Files:**
- Modify: `apps/desktop/src/renderer/pages/MessagingPage.tsx`
- Modify: `apps/desktop/src/renderer/pages/DevicesPage.tsx`
- Modify: `apps/desktop/src/renderer/components/BaofengChannelEditor.tsx`

- [ ] Persist Messaging active channel, destination, and draft.
- [ ] Track unread per channel and clear when a channel is selected/viewed.
- [ ] Persist Devices connection/RuView form values.
- [ ] Persist Baofeng selected port and auto-connect preference.
- [ ] Persist Baofeng channel draft separately from written radio state, with clear "unsaved draft" status.
- [ ] Verify edits survive switching away and app restart.

## Chunk 4: Button Polish and Verification

### Task 9: Clean misleading controls and placeholders

**Files:**
- Modify: `apps/desktop/src/renderer/pages/SettingsPage.tsx`
- Modify: `apps/desktop/src/renderer/pages/NetworkPage.tsx`
- Modify: `apps/desktop/src/renderer/pages/SonarPage.tsx`
- Modify as needed: related components under `apps/desktop/src/renderer/components`

- [ ] Change Settings "New PIN (optional)" wording to match actual Change PIN validation.
- [ ] Make Firmware/docs-only areas visually informational instead of appearing as missing action buttons.
- [ ] Hide or label Network static route placeholder as "not available yet" if no route data is wired.
- [ ] Hide or label Sonar filters that have no real signal source yet.
- [ ] Confirm all visible buttons have handlers and user feedback.

### Task 10: Final verification

**Files:**
- All edited files.

- [ ] Run `npm test --workspace=@ocp/tools-rtlsdr`.
- [ ] Run `npm run build --workspace=@ocp/desktop`.
- [ ] Run `ReadLints` for edited desktop files.
- [ ] Smoke-test every page:
  - Sonar: controls persist across tab switch.
  - Messaging: draft/channel/unread behavior works.
  - Network: row selection persists.
  - Devices: forms, selected tab, Baofeng draft persist.
  - Spectrum: local tuning, click retune, bookmarks, online session, Resume state.
  - Map: camera/layers/offline tile labels/center self.
  - Settings: PIN/plugin controls still work.
- [ ] Summarize remaining intentional limitations.

## Notes

- Do not commit unless the user explicitly asks.
- Do not auto-play SDR audio after restart.
- Do not implement signal GPS mapping.
- Preserve user/unrelated working-tree changes.
