# Translation guide

`app_en.arb` is the source-language catalog and English is the default locale.
Every visible UI message belongs in this catalog. Keep each message key stable;
renaming a key breaks generated Dart call sites and every translation.

## Adding or updating a translation

- Add or update `app_<language>.arb`, preserving every message key and every
  placeholder from `app_en.arb`.
- Read the `description` in the matching English `@key` metadata before
  translating. Preserve placeholders such as `{listName}` exactly, including
  their braces, and do not translate keyboard key names unless the platform
  convention requires it.
- This is a task-list application: use task/list/status vocabulary consistently.
  Do not translate task titles, list names, or custom tag names: they are user
  content.
- Run `flutter gen-l10n`, `flutter analyze`, and `flutter test` after catalog
  changes. Update widget tests when visible English text intentionally changes.

## Language setting

Supported application languages are declared by `AppLanguage` in
`lib/domain/models.dart`. Adding a locale requires its ARB catalog, an enum
value with a stable locale code, a localized language name in every catalog,
and inclusion in the cycle control in `workspace_screen.dart`.
