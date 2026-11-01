import 'dart:math' as math;

/// Geometry shared by the four handles, the preview and the exported crop.
class PhotoSelectionRect {
  const PhotoSelectionRect(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
  double get right => left + width;
  double get bottom => top + height;
  PhotoSelectionRect shift(double dx, double dy) =>
      PhotoSelectionRect(left + dx, top + dy, width, height);
}

enum PhotoSelectionCorner { topLeft, topRight, bottomLeft, bottomRight }

PhotoSelectionRect photoSelectionFit(
  double width,
  double height,
  double viewportWidth,
  double viewportHeight, {
  double padding = 24,
}) {
  if ([
    width,
    height,
    viewportWidth,
    viewportHeight,
  ].any((v) => !v.isFinite || v <= 0)) {
    throw ArgumentError('Dimensions invalides.');
  }
  final margin = math.min(padding, math.min(viewportWidth, viewportHeight) / 8);
  final scale = math.min(
    (viewportWidth - margin * 2) / width,
    (viewportHeight - margin * 2) / height,
  );
  final w = width * scale, h = height * scale;
  return PhotoSelectionRect(
    (viewportWidth - w) / 2,
    (viewportHeight - h) / 2,
    w,
    h,
  );
}

PhotoSelectionRect photoSelectionInitial(
  PhotoSelectionRect bounds, {
  double? ratio,
}) {
  if (ratio == null) return bounds;
  if (!ratio.isFinite || ratio <= 0) throw ArgumentError('Format invalide.');
  final w = math.min(bounds.width, bounds.height * ratio), h = w / ratio;
  return PhotoSelectionRect(
    bounds.left + (bounds.width - w) / 2,
    bounds.top + (bounds.height - h) / 2,
    w,
    h,
  );
}

PhotoSelectionRect photoSelectionBounds(
  PhotoSelectionRect image,
  double viewportWidth,
  double viewportHeight,
) {
  final left = math.max(0.0, image.left), top = math.max(0.0, image.top);
  final right = math.min(viewportWidth, image.right);
  final bottom = math.min(viewportHeight, image.bottom);
  return PhotoSelectionRect(
    left,
    top,
    math.max(0, right - left),
    math.max(0, bottom - top),
  );
}

PhotoSelectionRect photoSelectionMove(
  PhotoSelectionRect crop,
  PhotoSelectionRect bounds,
  double dx,
  double dy,
) => PhotoSelectionRect(
  (crop.left + dx)
      .clamp(bounds.left, math.max(bounds.left, bounds.right - crop.width))
      .toDouble(),
  (crop.top + dy)
      .clamp(bounds.top, math.max(bounds.top, bounds.bottom - crop.height))
      .toDouble(),
  crop.width,
  crop.height,
);

PhotoSelectionRect photoSelectionResize(
  PhotoSelectionRect crop,
  PhotoSelectionRect bounds,
  PhotoSelectionCorner corner,
  double dx,
  double dy, {
  double? ratio,
  double minimum = 48,
}) {
  if (![dx, dy, minimum].every((v) => v.isFinite) ||
      minimum <= 0 ||
      (ratio != null && (!ratio.isFinite || ratio <= 0))) {
    throw ArgumentError('Déplacement invalide.');
  }
  final leftSide =
      corner == PhotoSelectionCorner.topLeft ||
      corner == PhotoSelectionCorner.bottomLeft;
  final topSide =
      corner == PhotoSelectionCorner.topLeft ||
      corner == PhotoSelectionCorner.topRight;
  final ax = leftSide ? crop.right : crop.left,
      ay = topSide ? crop.bottom : crop.top;
  final maxW = leftSide ? ax - bounds.left : bounds.right - ax;
  final maxH = topSide ? ay - bounds.top : bounds.bottom - ay;
  final wantedW = crop.width + (leftSide ? -dx : dx);
  final wantedH = crop.height + (topSide ? -dy : dy);
  double w, h;
  if (ratio == null) {
    w = wantedW.clamp(math.min(minimum, maxW), maxW).toDouble();
    h = wantedH.clamp(math.min(minimum, maxH), maxH).toDouble();
  } else {
    final maximumWidth = math.min(maxW, maxH * ratio);
    final minimumWidth = math.min(
      maximumWidth,
      math.max(minimum, minimum * ratio),
    );
    w = ((wantedW + wantedH * ratio) / 2)
        .clamp(minimumWidth, maximumWidth)
        .toDouble();
    h = w / ratio;
  }
  return PhotoSelectionRect(
    leftSide ? ax - w : ax,
    topSide ? ay - h : ay,
    w,
    h,
  );
}

/// Keep the image behind the whole selection while the user drags or pinches it.
PhotoSelectionRect photoSelectionTransformImage(
  PhotoSelectionRect start,
  PhotoSelectionRect crop,
  double scale,
  double startX,
  double startY,
  double focalX,
  double focalY, {
  required double maximumWidth,
}) {
  if (![
        scale,
        startX,
        startY,
        focalX,
        focalY,
        maximumWidth,
      ].every((v) => v.isFinite) ||
      scale <= 0) {
    throw ArgumentError('Zoom invalide.');
  }
  final minimumScale = math.max(
    crop.width / start.width,
    crop.height / start.height,
  );
  final maximumScale = math.max(minimumScale, maximumWidth / start.width);
  final factor = scale.clamp(minimumScale, maximumScale).toDouble();
  final w = math.max(crop.width, start.width * factor),
      h = math.max(crop.height, start.height * factor);
  return PhotoSelectionRect(
    (focalX - (startX - start.left) * factor)
        .clamp(math.min(crop.left, crop.right - w), crop.left)
        .toDouble(),
    (focalY - (startY - start.top) * factor)
        .clamp(math.min(crop.top, crop.bottom - h), crop.top)
        .toDouble(),
    w,
    h,
  );
}

/// Source pixels use the exact same selection displayed on screen.
PhotoSelectionRect photoSelectionSource(
  PhotoSelectionRect crop,
  PhotoSelectionRect image,
  int imageWidth,
  int imageHeight,
) {
  if (imageWidth <= 0 ||
      imageHeight <= 0 ||
      image.width <= 0 ||
      image.height <= 0 ||
      crop.width <= 0 ||
      crop.height <= 0) {
    throw ArgumentError('Recadrage invalide.');
  }
  final left = ((crop.left - image.left) / image.width * imageWidth)
      .clamp(0.0, imageWidth.toDouble())
      .toDouble();
  final top = ((crop.top - image.top) / image.height * imageHeight)
      .clamp(0.0, imageHeight.toDouble())
      .toDouble();
  final right = ((crop.right - image.left) / image.width * imageWidth)
      .clamp(left, imageWidth.toDouble())
      .toDouble();
  final bottom = ((crop.bottom - image.top) / image.height * imageHeight)
      .clamp(top, imageHeight.toDouble())
      .toDouble();
  return PhotoSelectionRect(left, top, right - left, bottom - top);
}
