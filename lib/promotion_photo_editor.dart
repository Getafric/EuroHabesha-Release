import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PromotionPhotoController {
  ui.Image? image;
  String format = 'banner';
  double zoom = 1;
  Alignment alignment = Alignment.center;

  double get ratio => format == 'square' ? 1 : format == 'portrait' ? 9 / 16 : 16 / 9;

  Future<void> load(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      if (width <= 0 || height <= 0 || width > 20000 || height > 20000 ||
          width * height > 60000000) {
        throw StateError('Les dimensions de cette photo sont trop grandes.');
      }
      final scale = math.min(1.0, 1600 / math.max(width, height));
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (width * scale).round()),
        targetHeight: math.max(1, (height * scale).round()));
      final frame = await codec.getNextFrame();
      final old = image;
      image = frame.image;
      old?.dispose();
      reset();
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  void reset() {
    zoom = 1;
    alignment = Alignment.center;
  }

  Future<Uint8List> export() async {
    final current = image;
    if (current == null) throw StateError('Choisissez une photo.');
    final width = ratio >= 1 ? 1280 : (1280 * ratio).round();
    final height = ratio >= 1 ? (1280 / ratio).round() : 1280;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paint(canvas, Size(width.toDouble(), height.toDouble()));
    final picture = recorder.endRecording();
    try {
      final output = await picture.toImage(width, height);
      try {
        final data = await output.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Conversion de la photo impossible.');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        output.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  Rect destination(Size size) {
    final current = image!;
    final scale = math.max(size.width / current.width,
      size.height / current.height) * zoom;
    final width = current.width * scale;
    final height = current.height * scale;
    return Rect.fromLTWH((size.width - width) * (alignment.x + 1) / 2,
      (size.height - height) * (alignment.y + 1) / 2, width, height);
  }

  void paint(Canvas canvas, Size size) {
    final current = image;
    if (current == null) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawImageRect(current,
      Rect.fromLTWH(0, 0, current.width.toDouble(), current.height.toDouble()),
      destination(size), Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
  }

  void dispose() {
    image?.dispose();
    image = null;
  }
}

class PromotionPhotoEditor extends StatefulWidget {
  const PromotionPhotoEditor({super.key, required this.controller,
    required this.onChanged, this.enabled = true});
  final PromotionPhotoController controller;
  final VoidCallback onChanged;
  final bool enabled;
  @override
  State<PromotionPhotoEditor> createState() => _PromotionPhotoEditorState();
}

class _PromotionPhotoEditorState extends State<PromotionPhotoEditor> {
  double _startZoom = 1;
  static const _gold = Color(0xFFFFD700);

  void _change(VoidCallback action) {
    if (!widget.enabled) return;
    setState(action);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(children: [
      LayoutBuilder(builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 300 * controller.ratio);
        final size = Size(width, width / controller.ratio);
        return Center(child: Semantics(label: 'Recadrage de la photo de promotion',
          child: ClipRRect(borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onScaleStart: widget.enabled ? (_) => _startZoom = controller.zoom : null,
              onScaleUpdate: widget.enabled ? (details) => _change(() {
                controller.zoom = (_startZoom * details.scale).clamp(1.0, 3.0).toDouble();
                final rect = controller.destination(size);
                final extraX = rect.width - size.width;
                final extraY = rect.height - size.height;
                controller.alignment = Alignment(
                  extraX > 0 ? (controller.alignment.x -
                    2 * details.focalPointDelta.dx / extraX).clamp(-1.0, 1.0).toDouble() : 0,
                  extraY > 0 ? (controller.alignment.y -
                    2 * details.focalPointDelta.dy / extraY).clamp(-1.0, 1.0).toDouble() : 0,
                );
              }) : null,
              child: SizedBox(width: size.width, height: size.height,
                child: CustomPaint(painter: _PhotoPainter(controller))),
            ))));
      }),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: const {
        'banner': 'Bannière 16:9', 'square': 'Carré 1:1', 'portrait': 'Vertical 9:16',
      }.entries.map((entry) => ChoiceChip(
        label: Text(entry.value), selected: controller.format == entry.key,
        onSelected: widget.enabled ? (_) => _change(() {
          controller.format = entry.key;
          controller.reset();
        }) : null,
        selectedColor: _gold, backgroundColor: const Color(0xFF004D40),
        labelStyle: TextStyle(color: controller.format == entry.key
          ? const Color(0xFF061E12) : Colors.white),
      )).toList()),
      Row(children: [
        const Icon(Icons.zoom_in, color: _gold),
        Expanded(child: Slider(value: controller.zoom, min: 1, max: 3,
          activeColor: _gold, label: 'Zoom ${controller.zoom.toStringAsFixed(1)}',
          onChanged: widget.enabled ? (value) => _change(() => controller.zoom = value) : null)),
        TextButton(onPressed: widget.enabled ? () => _change(controller.reset) : null,
          child: const Text('Recentrer', style: TextStyle(color: _gold))),
      ]),
      const Text('Déplacez la photo pour la recadrer. La bannière est recommandée '
        'pour l’accueil. L’affichage final dépend de l’emplacement choisi.',
        style: TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.controller);
  final PromotionPhotoController controller;
  @override
  void paint(Canvas canvas, Size size) => controller.paint(canvas, size);
  @override
  bool shouldRepaint(covariant _PhotoPainter oldDelegate) => true;
}
