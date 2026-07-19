# Focus List Flutter

Local-first Flutter migration of the Rust Focus List application. It currently
targets Linux desktop, web, and Android from one codebase.

## Run

```sh
flutter pub get
flutter run -d linux
flutter run -d chrome
flutter run -d android
```

## Local data

Linux deliberately uses the existing Rust location:

```text
$XDG_DATA_HOME/tui-kanban/tasklists/
# or ~/.local/share/tui-kanban/tasklists/
```

Android uses private application-support storage. Web uses browser IndexedDB.
All three persist one schema-version-1 JSON-compatible task-list document per
list. Do not run the Rust application and the Flutter Linux application at the
same time: they use the same files and do not coordinate writes.

## Architecture

`lib/domain` contains immutable models and repository contracts.
`lib/data` contains JSON/local-store implementations. `lib/presentation`
contains Riverpod MVVM workspace state and widgets. Widgets do not access files
or IndexedDB directly.

The former Rust implementation and its migration notes are preserved on the
`legacy-rust` branch.
