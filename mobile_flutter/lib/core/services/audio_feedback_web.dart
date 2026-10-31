import 'dart:js_interop';

@JS('t2wPlaySound')
external void _t2wPlaySound(JSString type);

/// Web implementation of audio feedback via modern JS Interop
void playWebAudio(String soundType) {
  try {
    _t2wPlaySound(soundType.toJS);
  } catch (_) {}
}
