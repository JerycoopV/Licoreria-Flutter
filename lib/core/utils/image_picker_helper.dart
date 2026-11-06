import 'dart:convert';
import 'dart:typed_data';

import 'image_picker_io.dart'
    if (dart.library.js_interop) 'image_picker_web.dart';

class ImagePickerHelper {
  /// Abre el selector de imágenes del dispositivo (Android, Web o Windows)
  /// y devuelve la imagen codificada en formato `data:image/...;base64,...`.
  static Future<String?> pickImageAsDataUrl() {
    return pickProductImagePlatform();
  }

  /// Verifica si el string de imagen es un Data URL en Base64.
  static bool isDataUrl(String? imageStr) {
    if (imageStr == null) return false;
    return imageStr.trim().startsWith('data:image/');
  }

  /// Decodifica un Data URL (`data:image/...;base64,...`) a bytes (`Uint8List`).
  static Uint8List? decodeDataUrl(String? imageStr) {
    if (imageStr == null || !isDataUrl(imageStr)) return null;
    try {
      final commaIndex = imageStr.indexOf(',');
      if (commaIndex == -1) return null;
      final base64Part = imageStr.substring(commaIndex + 1).trim();
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }
}

