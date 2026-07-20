import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A terminal palette loaded from `assets/themes/*.json`.
///
/// Adding a JSON file with the same fields makes it available at the next app
/// launch; no Dart registry needs updating.
class AppThemeDefinition {
  const AppThemeDefinition({
    required this.id,
    required this.name,
    required this.background,
    required this.panel,
    required this.text,
    required this.muted,
    required this.accent,
    required this.pending,
    required this.doing,
    required this.done,
    required this.error,
  });

  final String id;
  final String name;
  final Color background;
  final Color panel;
  final Color text;
  final Color muted;
  final Color accent;
  final Color pending;
  final Color doing;
  final Color done;
  final Color error;

  factory AppThemeDefinition.fromJson(Map<String, Object?> json) {
    Color color(String field) {
      final value = json[field];
      if (value is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
        throw FormatException('Theme $field must be a #RRGGBB color');
      }
      return Color(int.parse(value.substring(1), radix: 16) | 0xff000000);
    }

    String text(String field) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Theme $field must be a non-empty string');
      }
      return value;
    }

    return AppThemeDefinition(
      id: text('id'),
      name: text('name'),
      background: color('background'),
      panel: color('panel'),
      text: color('text'),
      muted: color('muted'),
      accent: color('accent'),
      pending: color('pending'),
      doing: color('doing'),
      done: color('done'),
      error: color('error'),
    );
  }
}

class ThemeCatalog {
  const ThemeCatalog(this.themes);
  final List<AppThemeDefinition> themes;

  AppThemeDefinition byId(String id) =>
      themes.firstWhere((theme) => theme.id == id, orElse: () => themes.first);

  static final fallback = ThemeCatalog([classic, gruvbox]);

  /// Reads every declared JSON asset in assets/themes. Invalid additions are
  /// ignored so a bad custom theme cannot prevent the workspace from opening.
  static Future<ThemeCatalog> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final paths =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('assets/themes/') && path.endsWith('.json'),
            )
            .toList()
          ..sort();
    final themes = <AppThemeDefinition>[];
    for (final path in paths) {
      try {
        final raw = jsonDecode(await bundle.loadString(path));
        themes.add(
          AppThemeDefinition.fromJson(Map<String, Object?>.from(raw as Map)),
        );
      } on Object {
        // Keep valid themes usable when a user-authored file has a typo.
      }
    }
    if (themes.isEmpty || !themes.any((theme) => theme.id == classic.id)) {
      themes.insert(0, classic);
    }
    final ids = <String>{};
    return ThemeCatalog(themes.where((theme) => ids.add(theme.id)).toList());
  }
}

final themeCatalogProvider = Provider<ThemeCatalog>(
  (ref) => ThemeCatalog.fallback,
);

const classic = AppThemeDefinition(
  id: 'classic',
  name: 'Classic',
  background: Color(0xff0d0f18),
  panel: Color(0xff161926),
  text: Color(0xffdde0eb),
  muted: Color(0xff767c94),
  accent: Color(0xffb794f4),
  pending: Color(0xfff9bf60),
  doing: Color(0xff5dd3dc),
  done: Color(0xff7dcf91),
  error: Color(0xfff4707a),
);

const gruvbox = AppThemeDefinition(
  id: 'gruvbox',
  name: 'Gruvbox',
  background: Color(0xff282828),
  panel: Color(0xff3c3836),
  text: Color(0xffebdbb2),
  muted: Color(0xffa89984),
  accent: Color(0xffd79921),
  pending: Color(0xfffe8019),
  doing: Color(0xff83a598),
  done: Color(0xffb8bb26),
  error: Color(0xfffb4934),
);
