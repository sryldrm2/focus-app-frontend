import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

String apiBaseUrl() {
  const port = 5265;
  if (kIsWeb) {
    return 'http://localhost:$port/api';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:$port/api';
  }
  return 'http://localhost:$port/api';
}
