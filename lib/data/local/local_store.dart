import 'local_store_base.dart';
import 'local_store_stub.dart'
    if (dart.library.io) 'local_store_io.dart'
    if (dart.library.js_interop) 'local_store_web.dart'
    as implementation;

export 'local_store_base.dart';

PlatformLocalStore createPlatformLocalStore() =>
    implementation.createPlatformLocalStore();
