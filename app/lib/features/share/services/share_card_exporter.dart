import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a `RepaintBoundary` widget (the share-card) as a PNG and
/// hands it to the iOS share sheet via `share_plus`.
///
/// Pixel ratio: defaults to 3.0 (Instagram-ready ~1080×1920 from a
/// ~360×640 logical widget). On out-of-memory exceptions — rare but
/// possible on older 3GB devices with very long polylines — falls back
/// to 2.0 once. Beyond that, the exception bubbles up to the caller.
class ShareCardExporter {
  /// Capture the widget anchored by [boundaryKey] and trigger the iOS
  /// share sheet. The widget must be mounted inside a `RepaintBoundary`
  /// whose `key` matches [boundaryKey].
  ///
  /// [origin] anchors the share sheet/popover. iOS rejects a zero rect
  /// outright ("sharePositionOrigin must be non-zero"), so pass the rect of
  /// the triggering control (or the host view) — never the `Rect.zero` default.
  static Future<void> capture({
    required GlobalKey boundaryKey,
    String? subject,
    Rect origin = Rect.zero,
  }) async {
    final bytes = await _capturePngBytes(boundaryKey);
    if (bytes == null) {
      debugPrint('[ShareCardExporter] capture returned null — boundary not mounted');
      return;
    }

    // Write to temp dir so the share sheet can hand the file off to
    // Photos / Messages / Instagram. share_plus needs a file path, not
    // raw bytes — it copies into the target app's sandbox itself.
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/runcoach-share-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
        sharePositionOrigin: origin,
      ),
    );
  }

  static Future<Uint8List?> _capturePngBytes(GlobalKey boundaryKey) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // Try 3.0× first (Instagram-ready); on OOM drop to 2.0×.
    try {
      return await _toPngBytes(boundary, pixelRatio: 3.0);
    } catch (e) {
      debugPrint('[ShareCardExporter] toImage failed at 3.0×: $e — retry at 2.0×');
      return await _toPngBytes(boundary, pixelRatio: 2.0);
    }
  }

  static Future<Uint8List?> _toPngBytes(
    RenderRepaintBoundary boundary, {
    required double pixelRatio,
  }) async {
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }
}
