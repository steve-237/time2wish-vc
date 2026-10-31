// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web implementation of audio feedback via Web Audio API
void playWebAudio(String soundType) {
  try {
    js.context.callMethod('t2wPlaySound', [soundType]);
  } catch (_) {}
}
