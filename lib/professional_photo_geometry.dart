import 'dart:math' as math;

/// The same normalized frame is used for editing, preview and PNG export.
class ProfessionalPhotoRect {
  const ProfessionalPhotoRect(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

ProfessionalPhotoRect professionalPhotoRect({
  required double imageWidth,
  required double imageHeight,
  required double frameWidth,
  required double frameHeight,
  double zoom = 1,
  double alignmentX = 0,
  double alignmentY = 0,
  bool contain = false,
}) {
  final dimensions = [imageWidth, imageHeight, frameWidth, frameHeight];
  if (dimensions.any((v) => !v.isFinite || v <= 0) ||
      !zoom.isFinite ||
      !alignmentX.isFinite ||
      !alignmentY.isFinite) {
    throw ArgumentError('Dimensions de photo invalides.');
  }
  final sx = frameWidth / imageWidth, sy = frameHeight / imageHeight;
  final scale =
      (contain ? math.min(sx, sy) : math.max(sx, sy)) * zoom.clamp(1.0, 4.0);
  final width = imageWidth * scale, height = imageHeight * scale;
  return ProfessionalPhotoRect(
    (frameWidth - width) * (alignmentX.clamp(-1.0, 1.0) + 1) / 2,
    (frameHeight - height) * (alignmentY.clamp(-1.0, 1.0) + 1) / 2,
    width,
    height,
  );
}

double professionalPhotoDrag(double alignment, double delta, double freeSpace) {
  if (!alignment.isFinite || !delta.isFinite || !freeSpace.isFinite) {
    throw ArgumentError('Déplacement invalide.');
  }
  if (freeSpace.abs() < 0.001) return 0;
  return (alignment + 2 * delta / freeSpace).clamp(-1.0, 1.0).toDouble();
}
