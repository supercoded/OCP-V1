# OCP-V1 Decision Log

**Repo:** https://github.com/supercoded/OCP-V1  
**Process:** BMAD-style via workspace `_bmad/`

---

## 2026-07-12 — Repo cloned and project context initialized

**Question:** What is the verified starting point for the project?  
**Options considered:**
- Continue from empty workspace stub.
- Use the existing `supercoded/OCP-V1` repo as ground truth.

**Chosen:** Use `supercoded/OCP-V1` as ground truth. It already contains specs, scaffold, and a working Phase 4 Meshtastic bridge.

**Reason:** Avoids re-writing specs and scaffold. The build plan, charter, and PRS already exist and align with the offline-first goals.

**Reversibility:** Easy — the old stub is backed up as `OCP-V1-stub`.

---

## 2026-07-12 — Implementation start and architecture clarifications

**Question:** What should be built first, and how should the open research questions be resolved?  
**Mike's input:**
1. Start with Phase 1 from the list (fix deps + Phase 5 ONP / network layer).
2. Add Meshtastic firmware flashing support from the official GitHub repo so it stays current.
3. Auto-detect whatever transport is connected (TCP, serial, BLE).
4. Research and recommend SIMPLE vs PROTO mode.
5. Use host/device storage for MBTiles; research if it doesn't work.

**Decisions:**
1. **First implementation target:** fix the broken `npm test` baseline, then build the **ONP / network layer (Phase 5)**.
2. **Meshtastic serial mode:** Lock to **PROTO mode**. SIMPLE mode is a deprecated raw-bytes passthrough mode; OCP-V1's protobuf bridge is built around PROTO. If a legacy device only supports SIMPLE, we'll address it later.
3. **MBTiles storage:** Use **host/device app-documents storage** via Flutter `path_provider` (or Node/Electron `app.getPath('userData')`). This is the standard, works offline, and avoids cloud dependencies.
4. **Firmware flashing:** Add a script/package that fetches the latest Meshtastic firmware release from GitHub and flashes it using the correct tool for the target MCU (`esptool.py` for ESP32, `nrfutil` for nRF52/RAK4631).

**Reason:** Resolves the immediate blocker (`npm test`), then attacks the highest-value missing layer (network/peer state), while also making the bridge robust (auto-detect) and field-ready (firmware updates).

**Reversibility:** Medium — SIMPLE mode or cloud MBTiles storage can be added later without breaking the core.

---

## 2026-07-12 — Agentic process decision

**Question:** How should OpenClaw build and maintain this project?  
**Options considered:**
- Per-project ad-hoc agent prompts.
- Global BMAD-METHOD-derived process with named agents and memory files.

**Chosen:** Global BMAD-METHOD-derived process (`_bmad/`). Project-specific context lives in `project-context.md`, `PROJECT_STATUS.md`, `RESEARCH_LOG.md`, `DECISION_LOG.md`.

**Reason:** Reusable across all of Mike's apps, consistent memory hygiene, named agents, party-mode reviews.

**Reversibility:** Medium — would require migrating files back to project-only.
