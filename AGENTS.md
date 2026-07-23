# AGENTS.md

## Code exploration

When this repository contains a `.codegraph/` directory, use CodeGraph before
`rg`, file globbing, or direct file reads to understand or locate code:

- Start with `codegraph_explore` when the MCP tool is available, or run
  `codegraph explore "<question or symbol names>"` from the repository root.
- Search graph nodes and call paths first; use the returned source as already
  read rather than opening the same files again.
- Before broad or cross-layer edits, check the graph's impact radius with
  `codegraph impact <symbol>` (or ask `codegraph_explore` for the change's
  blast radius) to identify affected code and tests.
- Fall back to `rg`, globbing, or direct reads only when the graph does not
  answer the question, source is not indexed, or exact non-code content is
  required.
- Do not use CodeGraph when `.codegraph/` is absent; indexing remains the
  user's decision.

## Project scope

Treat this repository root as the active Flutter product. The former Rust
project is preserved on the `legacy-rust` branch; do not inspect, modify, test,
or couple new work to it unless the user explicitly asks for a Rust change.

All normal feature work must consider these Flutter targets:

- Android
- Web (Chrome/browser)
- Desktop (currently Linux)

Implement shared behavior once. Use platform-specific code only for storage,
OS integration, or intentionally different presentation. Do not silently make
a feature available on only one target.

## Working directory and commands

Run Flutter commands from the repository root:

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build web
```

Use `flutter run -d android`, `flutter run -d chrome`, or
`flutter run -d linux` for manual verification when appropriate. Do not run a
formatter over unrelated user changes. Before finishing, run at least
`flutter analyze` and `flutter test`; build the affected target for changes to
platform setup, plugins, storage, or release configuration.

## Architecture

Keep dependencies flowing in this direction:

```text
presentation -> domain <- data
                    ^
                  providers wire implementations together
```

- `lib/domain/models.dart`: immutable entities, enums, validation, JSON wire
  shapes, and platform-independent helpers.
- `lib/domain/repositories.dart`: repository contracts. Domain code must not
  import Flutter widgets, files, IndexedDB, or platform APIs.
- `lib/data/`: repository implementations and persistence adapters.
- `lib/data/local/local_store.dart`: conditional-import entry point. Preserve
  the IO/web/stub split; never import an IO implementation from shared code.
- `lib/data/providers.dart`: Riverpod dependency wiring.
- `lib/presentation/workspace_view_model.dart`: application state and actions.
  Persistence and business workflows belong here, not in widgets.
- `lib/presentation/workspace_screen.dart`: workspace widgets, keyboard and
  pointer interactions, and dialogs.
- `lib/app/focus_list_app.dart`: app-wide themes and typography.
- `lib/app/ui_mode.dart`: the deliberate presentation-mode boundary.
- `lib/presentation/terminal_style.dart`: terminal colors and measured font
  metrics. Reuse these values instead of introducing local approximations.

If a file becomes difficult to navigate, extract a cohesive widget or service;
do not create generic utility files containing unrelated helpers.

## Platform behavior

Android uses the touch-oriented Material presentation. Web and Linux use the
terminal presentation. Preserve this split unless the user requests a design
change. If Windows or macOS runners are added later, update `ui_mode.dart` and
its tests explicitly rather than assuming a presentation mode.

Platform-independent features must work through the same domain models,
repositories, and view model on all targets. Keep platform branching near the
boundary:

- storage differences belong in `lib/data/local/`;
- presentation differences use `usesTerminalPresentation`;
- avoid checks for `kIsWeb` or `defaultTargetPlatform` scattered through
  business logic;
- do not use `dart:io` in code compiled for web.

Linux and the legacy Rust app currently share the existing JSON data location.
Android uses application-support storage and web uses IndexedDB. Preserve
schema compatibility and backward-compatible defaults when changing
persistence. Do not change `schema_version`, stored field names, or migration
behavior without explicit tests and user approval.

## UI rules

The terminal presentation is content-measured, not based on fixed pixel row
heights. This is important because the user-configurable font ranges from 10 to
28 points.

- Do not add fixed heights around terminal text, tabs, task rows, footer rows,
  dialog titles, or inputs.
- Use the normalized terminal text theme (`height: 1`) and
  `TerminalMetrics` for measured character width, rendered font size, blank
  lines, and panel padding.
- Do not estimate character width or line height with magic divisors or fixed
  multipliers.
- Keep terminal vertical padding minimal and symmetric. Verify small, default,
  and maximum font sizes when changing typography.
- Do not add Material cards, chips, elevation, large headings, ripples,
  floating action buttons, or rounded web-style controls to terminal mode.
- Terminal dialogs, text fields, floating labels, buttons, menus, settings,
  help, and confirmations must match the workspace typography and density.
- Floating labels must not overlap the outline or editable text. Scale their
  notch and content clearance with the configured font.
- Preserve pointer targets, tooltips/semantics, focus behavior, and keyboard
  shortcuts even when controls look like terminal text.
- Keep long horizontal terminal rows scrollable instead of shrinking text or
  allowing overflow.
- Android controls may retain Material spacing, animation, icons, and touch
  affordances. A terminal-only adjustment must not accidentally alter Android.

Use the existing Ubuntu Mono Nerd Font assets. Do not replace or download fonts
without an explicit request and license review.

## State and feature changes

Widgets must not write storage directly. Add or update a view-model action,
call a repository contract, and expose immutable state to the widget tree.
Keep async persistence errors visible through state/notices rather than
swallowing them.

When adding a setting:

1. Add the validated field and backward-compatible default to `AppSettings`.
2. Update JSON serialization without breaking older stored settings.
3. Add view-model mutation/persistence behavior.
4. Add controls for Android and terminal presentation where applicable.
5. Test defaults, validation, persistence, and both presentation branches.

When adding a task/list feature, check list, focus, completed, and multi views,
plus keyboard and pointer access where relevant.

## Testing expectations

Place tests alongside the layer being changed:

- `test/data/`: storage and repository behavior;
- `test/presentation/workspace_view_model_test.dart`: state transitions and
  persistence workflows;
- `test/presentation/workspace_screen_test.dart`: rendering, interaction,
  overflow, semantics, dialogs, and font scaling;
- `test/app/`: presentation-mode and app configuration behavior.

For terminal widget tests, explicitly set the target platform to Linux and
restore the override before the test ends. Test constrained and normal window
sizes. Typography changes must include a wrapped two-line task at the maximum
font size and should verify geometry rather than relying only on `findsOneWidget`.
For Android-specific UI changes, explicitly select Android in the test.

Prefer repository fakes through Riverpod provider overrides. Do not depend on
real files, IndexedDB, wall-clock delays, or external services in widget/unit
tests.

## Change discipline

- Preserve unrelated work in a dirty worktree.
- Keep changes inside this repository unless updating this instruction file or
  the user explicitly requests another scope.
- Do not add dependencies when Flutter/Dart or an existing package already
  provides the needed behavior.
- Update tests with behavior changes; do not weaken assertions merely to make
  failures disappear.
- Keep accessibility labels and keyboard behavior stable unless the feature
  intentionally changes them.
- Summarize affected platforms and verification commands in the final handoff.
