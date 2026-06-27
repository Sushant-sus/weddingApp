// One-off: convert the brand icon webp into a PNG that flutter_launcher_icons
// can consume. Run with: dart run tool/gen_icon_png.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = File('assets/brand/icon.webp').readAsBytesSync();
  final decoded = img.decodeImage(src);
  if (decoded == null) {
    stderr.writeln('Failed to decode assets/brand/icon.webp');
    exit(1);
  }
  // Ensure a square 1024 PNG.
  final resized = img.copyResize(decoded, width: 1024, height: 1024);
  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(resized));
  stdout.writeln('Wrote assets/icon/icon.png (${resized.width}x${resized.height})');
}
