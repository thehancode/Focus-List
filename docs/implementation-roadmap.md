# Roadmap implementation record

This file records the decisions for implementing roadmap items 1–6. Keep it
updated as phases are completed or implementation discoveries change a detail.

## Targets and verification

- Terminal features target Linux and web. Android keeps its current UI while
  sharing domain models, repositories, projections, and business actions.
- Background images target Linux only; the boundary must remain suitable for a
  later Windows implementation.
- Full Flutter command output goes to ignored `.buildlog/*.log` files. Poll the
  command and inspect summaries instead of printing whole logs.
- Run focused tests while developing, one analyze/test checkpoint after phase
  3, and final analyze/test plus Linux/web builds after phase 6.
- Do not create git commits unless the user explicitly requests them.

## Locked behavior

- New tasks start empty; a new subtask leaves its parent selected.
- Long-title cycle: Wrap selected, Wrap all, Sliding window, Marquee. Legacy
  `wrap` maps to Wrap all and legacy/missing `marquee` maps to Marquee.
- Sliding windows overlap by five characters, pause on the end-aligned window,
  then restart.
- Left/right cycle lists; Tab creates a subtask; Space chords retain the 750 ms
  timeout. Space then Space completes the selected subtree.
- Ctrl+C and double-click copy the selected raw title. Ctrl+Shift+C copies the
  selected status section as tab-indented task text with tag glyphs and flashes
  the involved rows for 100 ms.
- Ctrl+Z undoes up to 50 successful content edits; settings, navigation,
  automatic resets, search, and transient effects are excluded. No redo.
- Device state stores view, list, selection, sound, seen tips, and desktop
  appearance separately from task data and portable settings.
- Linux background selection uses a native picker and remembers the absolute
  source path. Fit modes are Cover and Contain; missing files fall back safely.
- At most one unseen tip appears per launch for three seconds. Tips can be
  disabled and remain browseable from Help.
- Completion rewards have 0.2 probability, are nonblocking, use varied
  localized terminal celebrations, and last 400/800/1400 ms for
  short/medium/long (medium default).
- Search uses Ctrl+F or `/`, performs case-insensitive literal title matching,
  includes collapsed descendants, follows current-list versus multi scope,
  wraps titles temporarily, uses cyan/amber highlights, and closes on Enter
  while retaining selection.

## Progress

- [x] Phase 1: immediate correctness fixes
- [x] Phase 2: long-title modes
- [x] Phase 3: commands, copying, completion, and undo
- [x] Intermediate analyze/test checkpoint
- [x] Phase 4: device state and Linux background
- [x] Phase 5: tips and completion rewards
- [x] Phase 6: search
- [x] Final analyze/test and Linux/web builds

Final verification completed successfully on 2026-07-21. Full command output is
available in `.buildlog/analyze-verified-final.log`,
`.buildlog/test-verified-final.log`, `.buildlog/build-web-final.log`, and
`.buildlog/build-linux-final.log`.
