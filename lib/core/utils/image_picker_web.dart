import 'dart:async';
import 'dart:js_interop';

@JS('document.createElement')
external _JSInputElement _createElement(JSString tagName);

extension type _JSInputElement(JSObject _) implements JSObject {
  external set type(JSString value);
  external set accept(JSString value);
  external _JSFileList? get files;
  external set onchange(JSFunction? callback);
  external void click();
}

extension type _JSFileList(JSObject _) implements JSObject {
  external int get length;
  external _JSFile? item(int index);
}

extension type _JSFile(JSObject _) implements JSObject {}

@JS('FileReader')
extension type _JSFileReader._(JSObject _) implements JSObject {
  external factory _JSFileReader();
  external JSAny? get result;
  external set onload(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external void readAsDataURL(_JSFile blob);
}

Future<String?> pickProductImagePlatform() {
  final completer = Completer<String?>();
  try {
    final input = _createElement('input'.toJS);
    input.type = 'file'.toJS;
    input.accept = 'image/*'.toJS;

    input.onchange = ((JSAny? _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final reader = _JSFileReader();
      reader.onload = ((JSAny? _) {
        final res = reader.result;
        final dataUrl = (res as JSString?)?.toDart;
        if (!completer.isCompleted) completer.complete(dataUrl);
      }).toJS;
      reader.onerror = ((JSAny? _) {
        if (!completer.isCompleted) completer.complete(null);
      }).toJS;
      reader.readAsDataURL(file);
    }).toJS;

    input.click();
  } catch (_) {
    if (!completer.isCompleted) completer.complete(null);
  }
  return completer.future;
}

