import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// The caller owns the returned image and must dispose it. Encoded descriptor
/// width/height are not available on Flutter Web; use the byte codec there.
Future<ui.Image> decodeProfessionalPhotoForCrop(
  Uint8List bytes, {
  bool useWebDecoder = kIsWeb,
}) async {
  if (bytes.isEmpty) {
    throw StateError('Le fichier photo est vide.');
  }
  if (bytes.length > 8 * 1024 * 1024) {
    throw StateError('Choisissez une photo de 8 Mo maximum.');
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    // Own the byte range: some picker results are views into a larger buffer.
    final ownedBytes = Uint8List.fromList(bytes);
    if (useWebDecoder) {
      codec = await ui.instantiateImageCodec(
        ownedBytes,
        targetWidth: 2000,
        allowUpscaling: false,
      );
    } else {
      buffer = await ui.ImmutableBuffer.fromUint8List(ownedBytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width, height = descriptor.height;
      if (width < 1 ||
          height < 1 ||
          width > 20000 ||
          height > 20000 ||
          width * height > 60000000) {
        throw StateError('Dimensions trop grandes. Réduisez cette photo.');
      }
      final factor = math.min(1.0, 2000 / math.max(width, height));
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (width * factor).round()),
        targetHeight: math.max(1, (height * factor).round()),
      );
    }
    final image = (await codec.getNextFrame()).image;
    if (image.width < 1 ||
        image.height < 1 ||
        image.width > 20000 ||
        image.height > 20000 ||
        image.width * image.height > 60000000) {
      image.dispose();
      throw StateError('Dimensions trop grandes. Réduisez cette photo.');
    }
    return image;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
