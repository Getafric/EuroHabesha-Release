import 'l10n/app_ui.dart';
import 'professional_photo_decode.dart';

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'professional_photo_selection.dart';

// EH_CADRAGE_COINS_V3 — shared by banners, profiles, covers and service photos.
enum ProfessionalPhotoUse { banner, cover, logo, presentation, gallery }

Future<Uint8List?> frameProfessionalPhoto(
  BuildContext context, {
  required Uint8List bytes,
  required ProfessionalPhotoUse use,
}) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoSelectionScreen(bytes: bytes, use: use),
    ),
  );
}

class _PhotoSelectionScreen extends StatefulWidget {
  const _PhotoSelectionScreen({required this.bytes, required this.use});
  final Uint8List bytes;
  final ProfessionalPhotoUse use;
  @override
  State<_PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<_PhotoSelectionScreen> {
  static const _gold = Color(0xFFFFD700), _green = Color(0xFF061E12);
  ui.Image? _image;
  String? _error;
  Size? _viewport;
  PhotoSelectionRect? _imageRect, _selection, _fitRect, _gestureStart;
  Offset _focalStart = Offset.zero;
  final Map<int, Offset> _pointers = {};
  int? _activePointer;
  PhotoSelectionCorner? _activeCorner;
  double _startDistance = 1;
  double? _ratio;
  bool _movePhoto = false, _preview = false, _saving = false;
  bool get _logo => widget.use == ProfessionalPhotoUse.logo;

  @override
  void initState() {
    super.initState();
    _ratio = _logo ? 1 : null;
    _load();
  }

  Future<void> _load() async {
    try {
      final image = await decodeProfessionalPhotoForCrop(widget.bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = error is StateError ? error.message.toString() : 'Photo illisible ou format non pris en charge. Essayez une image JPEG, PNG ou WebP.',
      );
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _layout(Size size) {
    if (size == _viewport) return;
    final old = _viewport;
    _viewport = size;
    _fitRect = photoSelectionFit(
      _image!.width.toDouble(),
      _image!.height.toDouble(),
      size.width,
      size.height,
    );
    if (old == null || _imageRect == null || _selection == null) {
      _reset();
    } else {
      // Preserve the source crop through orientation/window-size changes.
      final factor = math.min(size.width / old.width, size.height / old.height);
      final dx = (size.width - old.width * factor) / 2;
      final dy = (size.height - old.height * factor) / 2;
      PhotoSelectionRect scale(PhotoSelectionRect r) => PhotoSelectionRect(
        r.left * factor + dx,
        r.top * factor + dy,
        r.width * factor,
        r.height * factor,
      );
      _imageRect = scale(_imageRect!);
      _selection = scale(_selection!);
      if (_selection!.left < 0 ||
          _selection!.top < 0 ||
          _selection!.right > size.width ||
          _selection!.bottom > size.height) {
        _reset();
      }
    }
  }

  void _reset() {
    _imageRect = _fitRect;
    _selection = photoSelectionInitial(_fitRect!, ratio: _ratio);
  }

  PhotoSelectionRect get _bounds =>
      photoSelectionBounds(_imageRect!, _viewport!.width, _viewport!.height);

  Map<PhotoSelectionCorner, Offset> get _corners => {
    PhotoSelectionCorner.topLeft: Offset(_selection!.left, _selection!.top),
    PhotoSelectionCorner.topRight: Offset(_selection!.right, _selection!.top),
    PhotoSelectionCorner.bottomLeft: Offset(
      _selection!.left,
      _selection!.bottom,
    ),
    PhotoSelectionCorner.bottomRight: Offset(
      _selection!.right,
      _selection!.bottom,
    ),
  };

  Offset get _focalPoint {
    final points = _pointers.values.take(2).toList();
    return points.fold(Offset.zero, (sum, point) => sum + point) /
        points.length.toDouble();
  }

  double get _pointerDistance {
    final points = _pointers.values.take(2).toList();
    return points.length < 2
        ? 1
        : math.max(1.0, (points[0] - points[1]).distance);
  }

  void _beginPhotoGesture() {
    if (_pointers.isEmpty) {
      _gestureStart = null;
      return;
    }
    _gestureStart = _imageRect;
    _focalStart = _focalPoint;
    _startDistance = _pointerDistance;
  }

  void _pointerDown(PointerDownEvent event) {
    if (_saving || _preview) return;
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 1) {
      _activeCorner = null;
      _activePointer = null;
      var nearest = double.infinity;
      for (final entry in _corners.entries) {
        final delta = event.localPosition - entry.value;
        if (delta.dx.abs() <= 24 &&
            delta.dy.abs() <= 24 &&
            delta.distance < nearest) {
          nearest = delta.distance;
          _activeCorner = entry.key;
          _activePointer = event.pointer;
        }
      }
      if (_activePointer == null &&
          !_movePhoto &&
          Rect.fromLTWH(
            _selection!.left,
            _selection!.top,
            _selection!.width,
            _selection!.height,
          ).contains(event.localPosition)) {
        _activePointer = event.pointer;
      }
    }
    if (_movePhoto && _activePointer == null) _beginPhotoGesture();
  }

  void _pointerMove(PointerMoveEvent event) {
    final previous = _pointers[event.pointer];
    if (previous == null || _saving || _preview) return;
    _pointers[event.pointer] = event.localPosition;
    final delta = event.localPosition - previous;
    if (_activePointer == event.pointer) {
      setState(() {
        if (_activeCorner != null) {
          _selection = photoSelectionResize(
            _selection!,
            _bounds,
            _activeCorner!,
            delta.dx,
            delta.dy,
            ratio: _ratio,
          );
        } else if (!_movePhoto) {
          _selection = photoSelectionMove(
            _selection!,
            _bounds,
            delta.dx,
            delta.dy,
          );
        }
      });
    } else if (_movePhoto && _activePointer == null && _gestureStart != null) {
      final focal = _focalPoint;
      setState(
        () => _imageRect = photoSelectionTransformImage(
          _gestureStart!,
          _selection!,
          _pointers.length > 1 ? _pointerDistance / _startDistance : 1,
          _focalStart.dx,
          _focalStart.dy,
          focal.dx,
          focal.dy,
          maximumWidth: _fitRect!.width * 6,
        ),
      );
    }
  }

  void _pointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_activePointer == event.pointer) {
      _activePointer = null;
      _activeCorner = null;
    }
    if (_movePhoto) _beginPhotoGesture();
  }

  Rect _sourceRect() {
    final r = photoSelectionSource(
      _selection!,
      _imageRect!,
      _image!.width,
      _image!.height,
    );
    return Rect.fromLTWH(r.left, r.top, r.width, r.height);
  }

  Future<void> _confirm() async {
    if (_saving || _image == null || _selection == null) return;
    setState(() => _saving = true);
    try {
      final source = _sourceRect();
      final factor = math.min(
        1.0,
        1280 / math.max(source.width, source.height),
      );
      final width = math.max(1, (source.width * factor).round());
      final height = math.max(1, (source.height * factor).round());
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        _image!,
        source,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      late Uint8List bytes;
      try {
        final image = await picture.toImage(width, height);
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) throw StateError('Conversion impossible.');
          bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        } finally {
          image.dispose();
        }
      } finally {
        picture.dispose();
      }
      if (mounted) Navigator.of(context).pop(bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(
              'Recadrage impossible. Modifiez le cadre puis réessayez.',
            ),
          ),
        );
      }
    }
  }

  Widget _handle(PhotoSelectionCorner corner, double x, double y) => Positioned(
    key: ValueKey('photo-crop-${corner.name}'),
    left: x - 24,
    top: y - 24,
    width: 48,
    height: 48,
    child: Semantics(
      label:
          'Coin ${switch (corner) {
            PhotoSelectionCorner.topLeft => 'supérieur gauche',
            PhotoSelectionCorner.topRight => 'supérieur droit',
            PhotoSelectionCorner.bottomLeft => 'inférieur gauche',
            PhotoSelectionCorner.bottomRight => 'inférieur droit',
          }} : glissez pour redimensionner le cadre',
      child: CustomPaint(painter: _CornerPainter(corner)),
    ),
  );

  Widget _editor(Size size) {
    _layout(size);
    final crop = _selection!;
    // Claim pointers only inside the canvas. Outside it, the page still scrolls.
    // Raw pointer positions prevent the outer scroll view stealing corner drags.
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (_) {},
            ),
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerEnd,
        onPointerCancel: _pointerEnd,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SelectionPainter(
                  image: _image!,
                  imageRect: _imageRect!,
                  selection: crop,
                  logo: _logo,
                ),
              ),
            ),
            if (!_movePhoto)
              Positioned(
                left: crop.left + 18,
                top: crop.top + 18,
                width: math.max(1, crop.width - 36),
                height: math.max(1, crop.height - 36),
                child: Semantics(
                  label: 'Glissez le cadre pour déplacer la sélection',
                  child: const Center(
                    child: Icon(
                      Icons.open_with,
                      size: 24,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            _handle(PhotoSelectionCorner.topLeft, crop.left, crop.top),
            _handle(PhotoSelectionCorner.topRight, crop.right, crop.top),
            _handle(PhotoSelectionCorner.bottomLeft, crop.left, crop.bottom),
            _handle(PhotoSelectionCorner.bottomRight, crop.right, crop.bottom),
          ],
        ),
      ),
    );
  }

  Widget _previewImage() => LayoutBuilder(
    builder: (context, constraints) {
      final source = _sourceRect(), aspect = source.width / source.height;
      final width = math.min(
        constraints.maxWidth - 32,
        (constraints.maxHeight - 32) * aspect,
      );
      final image = SizedBox(
        width: math.max(1, width),
        height: math.max(1, width / aspect),
        child: CustomPaint(painter: _CropPreviewPainter(_image!, source)),
      );
      return Center(child: _logo ? ClipOval(child: image) : image);
    },
  );

  Widget _modeChip(String label, bool photo) => ChoiceChip(
    label: Text(label),
    selected: _movePhoto == photo,
    selectedColor: _gold,
    backgroundColor: const Color(0xFF004D40),
    checkmarkColor: _green,
    labelStyle: TextStyle(color: _movePhoto == photo ? _green : Colors.white),
    onSelected: _saving ? null : (_) => setState(() => _movePhoto = photo),
  );

  Widget _formats() {
    final formats = _logo
        ? <String, double?>{'Profil carré': 1}
        : <String, double?>{
            'Libre': null,
            'Carré': 1,
            'Bannière': 2.5,
            'Paysage': 16 / 9,
            'Portrait': 4 / 5,
          };
    final selected = formats.entries
        .firstWhere((entry) => entry.value == _ratio)
        .key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          SizedBox(
            width: 175,
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              dropdownColor: const Color(0xFF004D40),
              iconEnabledColor: _gold,
              style: const TextStyle(color: _gold, fontSize: 14),
              items: [
                for (final label in formats.keys)
                  DropdownMenuItem(
                    value: label,
                    child: AppText('Format : $label'),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (label) {
                      if (label == null) return;
                      setState(() {
                        _ratio = formats[label];
                        _selection = photoSelectionInitial(
                          _bounds,
                          ratio: _ratio,
                        );
                      });
                    },
            ),
          ),
          TextButton.icon(
            onPressed: _saving ? null : () => setState(_reset),
            icon: const Icon(Icons.restart_alt, color: _gold),
            label: const AppText(
              'Réinitialiser',
              style: TextStyle(color: _gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_preview) {
                        setState(() => _preview = false);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
              child: Text(
                _preview ? 'Modifier le cadre' : 'Annuler',
                style: const TextStyle(color: _gold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _green,
              ),
              onPressed: _saving || _image == null
                  ? null
                  : () {
                      if (_selection == null) return;
                      if (_preview) {
                        _confirm();
                      } else {
                        setState(() => _preview = true);
                      }
                    },
              child: Text(
                _saving
                    ? 'Préparation…'
                    : _preview
                    ? 'Utiliser cette photo'
                    : 'Voir le résultat',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: _green,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: _gold,
        title: Text(_preview ? 'Aperçu du découpage' : 'Découper ma photo'),
        automaticallyImplyLeading: !_saving,
      ),
      bottomNavigationBar: _image == null ? null : _actions(),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: _gold,
                      ),
                      label: const AppText(
                        'Retour pour choisir une autre photo',
                        style: TextStyle(color: _gold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _image == null
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasHeight = math.max(
                    240.0,
                    math.min(420.0, constraints.maxHeight * 0.62),
                  );
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            _preview
                                ? 'Seule cette partie sera conservée.'
                                : _movePhoto
                                ? 'Glissez la photo ou pincez pour la placer dans le cadre. Les quatre coins restent réglables.'
                                : 'Tirez les quatre coins dorés pour choisir la partie à garder. Glissez au centre pour déplacer le cadre.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!_preview)
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            alignment: WrapAlignment.center,
                            children: [
                              _modeChip('Déplacer le cadre', false),
                              _modeChip('Déplacer la photo', true),
                            ],
                          ),
                        SizedBox(
                          height: canvasHeight,
                          child: _preview
                              ? _previewImage()
                              : LayoutBuilder(
                                  builder: (context, canvas) => _editor(
                                    Size(canvas.maxWidth, canvas.maxHeight),
                                  ),
                                ),
                        ),
                        if (!_preview) _formats(),
                        if (!_preview && _logo)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: AppText(
                              'Le cercle indique la partie visible sur le profil.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    ),
  );
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.image,
    required this.imageRect,
    required this.selection,
    required this.logo,
  });
  final ui.Image image;
  final PhotoSelectionRect imageRect, selection;
  final bool logo;
  @override
  void paint(Canvas canvas, Size size) {
    final target = Rect.fromLTWH(
      imageRect.left,
      imageRect.top,
      imageRect.width,
      imageRect.height,
    );
    final crop = Rect.fromLTWH(
      selection.left,
      selection.top,
      selection.width,
      selection.height,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(const Color(0xFF15251B), BlendMode.src);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      target,
      Paint()..filterQuality = FilterQuality.high,
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(crop);
    canvas.drawPath(
      mask,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(crop.left + crop.width * i / 3, crop.top),
        Offset(crop.left + crop.width * i / 3, crop.bottom),
        line,
      );
      canvas.drawLine(
        Offset(crop.left, crop.top + crop.height * i / 3),
        Offset(crop.right, crop.top + crop.height * i / 3),
        line,
      );
    }
    canvas.drawRect(
      crop,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (logo) {
      final corners = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(crop)
        ..addOval(crop);
      canvas.drawPath(
        corners,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
      canvas.drawOval(
        crop,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) => true;
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(this.corner);
  final PhotoSelectionCorner corner;
  @override
  void paint(Canvas canvas, Size size) {
    final left =
        corner == PhotoSelectionCorner.topLeft ||
        corner == PhotoSelectionCorner.bottomLeft;
    final top =
        corner == PhotoSelectionCorner.topLeft ||
        corner == PhotoSelectionCorner.topRight;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + Offset(left ? 16 : -16, 0), paint);
    canvas.drawLine(center, center + Offset(0, top ? 16 : -16), paint);
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFFFD700));
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.corner != corner;
}

class _CropPreviewPainter extends CustomPainter {
  const _CropPreviewPainter(this.image, this.source);
  final ui.Image image;
  final Rect source;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    source,
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.high,
  );
  @override
  bool shouldRepaint(covariant _CropPreviewPainter oldDelegate) => true;
}
