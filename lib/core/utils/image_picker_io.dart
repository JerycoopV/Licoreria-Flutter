import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _channel =
    MethodChannel('com.example.licoreria_pos/image_picker');

Future<String?> pickProductImagePlatform() async {
  if (Platform.isAndroid) {
    try {
      final result = await _channel.invokeMethod<String>('pickImage');
      return result;
    } catch (_) {
      return null;
    }
  }

  if (Platform.isWindows) {
    try {
      const psScript = '''
Add-Type -AssemblyName System.Windows.Forms
\$dlg = New-Object System.Windows.Forms.OpenFileDialog
\$dlg.Filter = "Imagenes (*.png;*.jpg;*.jpeg;*.webp)|*.png;*.jpg;*.jpeg;*.webp"
\$dlg.Title = "Seleccionar imagen del producto"
if (\$dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dlg.FileName
}
''';
      final proc = await Process.run(
        'powershell',
        ['-NoProfile', '-STA', '-Command', psScript],
      );
      final path = proc.stdout.toString().trim();
      if (path.isEmpty) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final ext = path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  return null;
}

