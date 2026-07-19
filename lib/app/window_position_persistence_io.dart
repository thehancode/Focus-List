import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'window_position_persistence_base.dart';

WindowPositionPersistence createWindowPositionPersistence() =>
    _DesktopWindowPositionPersistence();

class _DesktopWindowPositionPersistence
    with WindowListener
    implements WindowPositionPersistence {
  static const _fileName = 'window-position.json';

  Timer? _debounce;
  Future<void> _writes = Future.value();
  bool _listening = false;
  Rect? _latestBounds;

  bool get _isSupported => supportsWindowBoundsPersistence(
    isLinux: Platform.isLinux,
    isWindows: Platform.isWindows,
    sessionType: Platform.environment['XDG_SESSION_TYPE'],
    waylandDisplay: Platform.environment['WAYLAND_DISPLAY'],
    gdkBackend: Platform.environment['GDK_BACKEND'],
  );

  @override
  Future<Rect?> load() async {
    if (!_isSupported) return null;
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      final value = Map<String, Object?>.from(
        jsonDecode(await file.readAsString()) as Map,
      );
      return boundsFromJson(value);
    } on Object {
      return null;
    }
  }

  @override
  void start() {
    if (!_isSupported || _listening) return;
    _listening = true;
    windowManager.addListener(this);
    _captureBounds();
  }

  @override
  Future<void> dispose() async {
    _debounce?.cancel();
    if (_listening) windowManager.removeListener(this);
    _listening = false;
    if (_latestBounds != null) await _queueSave(_latestBounds!);
    await _writes;
  }

  @override
  void onWindowMove() => _captureBounds();

  @override
  void onWindowMoved() => _captureBounds();

  @override
  void onWindowResize() => _captureBounds();

  @override
  void onWindowResized() => _captureBounds();

  void _captureBounds() {
    unawaited(() async {
      _latestBounds = await windowManager.getBounds();
      _scheduleSave();
    }());
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final bounds = _latestBounds;
      if (bounds != null) unawaited(_queueSave(bounds));
    });
  }

  Future<void> _queueSave(Rect bounds) {
    _writes = _writes.then((_) async {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert({'left': bounds.left, 'top': bounds.top, 'right': bounds.right, 'bottom': bounds.bottom})}\n',
        flush: true,
      );
      await temporary.rename(file.path);
    });
    return _writes;
  }

  Future<File> _file() async {
    if (Platform.isLinux) {
      final stateHome =
          Platform.environment['XDG_STATE_HOME'] ??
          path.join(Platform.environment['HOME'] ?? '', '.local', 'state');
      return File(path.join(stateHome, 'tui-kanban', _fileName));
    }
    final support = await getApplicationSupportDirectory();
    return File(path.join(support.path, 'focus-list', _fileName));
  }
}
