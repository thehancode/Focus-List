import 'dart:ui';

abstract interface class WindowPositionPersistence {
  Future<Rect?> load();
  void start();
  Future<void> dispose();
}

/// Whether the native window system permits applications to restore absolute
/// bounds. Wayland compositors intentionally own window placement, while X11
/// and Windows allow applications to request it.
bool supportsWindowBoundsPersistence({
  required bool isLinux,
  required bool isWindows,
  required String? sessionType,
  required String? waylandDisplay,
  required String? gdkBackend,
}) {
  if (isWindows) return true;
  if (!isLinux) return false;

  final backends = gdkBackend
      ?.toLowerCase()
      .split(',')
      .map((value) => value.trim())
      .toSet();
  if (backends?.contains('x11') ?? false) return true;
  if (backends?.contains('wayland') ?? false) return false;

  return sessionType?.toLowerCase() != 'wayland' &&
      (waylandDisplay == null || waylandDisplay.isEmpty);
}

/// Converts persisted window corners into Flutter window bounds.
///
/// The previous position-only shape is accepted so existing saved positions
/// continue to work after upgrading.
Rect? boundsFromJson(Map<String, Object?>? value) {
  if (value == null) return null;
  final left = value['left'];
  final top = value['top'];
  final right = value['right'];
  final bottom = value['bottom'];
  if (left is num &&
      top is num &&
      right is num &&
      bottom is num &&
      left.isFinite &&
      top.isFinite &&
      right.isFinite &&
      bottom.isFinite &&
      right > left &&
      bottom > top) {
    return Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      right.toDouble(),
      bottom.toDouble(),
    );
  }

  final x = value['x'];
  final y = value['y'];
  if (x is! num || y is! num || !x.isFinite || !y.isFinite) return null;
  return Rect.fromLTWH(x.toDouble(), y.toDouble(), 1100, 720);
}
