import 'dart:js_interop';

@JS('t2wDownloadFile')
external void _t2wDownloadFile(JSString filename, JSString content, JSString mimeType);

@JS('t2wPickFile')
external JSPromise<JSString> _t2wPickFile(JSString accept);

void downloadFilePlatform(String filename, String content, String mimeType) {
  try {
    _t2wDownloadFile(filename.toJS, content.toJS, mimeType.toJS);
  } catch (_) {}
}

Future<String?> pickJsonFilePlatform() async {
  try {
    final jsPromise = _t2wPickFile('.json,application/json,text/plain'.toJS);
    final jsStr = await jsPromise.toDart;
    final text = jsStr.toDart;
    return text.trim().isEmpty ? null : text;
  } catch (_) {
    return null;
  }
}
