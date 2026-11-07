import 'l10n/app_ui.dart';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'event_qr_documents.dart';
import 'public_event_route_screen.dart';

/// Public event navigation only. Admission stays in the organizer's scanner.
class QrScannerEntryScreen extends StatefulWidget {
  const QrScannerEntryScreen({super.key});
  @override
  State<QrScannerEntryScreen> createState() => _QrScannerEntryScreenState();
}

class _QrScannerEntryScreenState extends State<QrScannerEntryScreen> {
  static const _dark = Color(0xFF061E12);
  static const _gold = Color(0xFFFFD700);
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handling = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || !mounted) return;
    final codes = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (codes.isEmpty) return;
    setState(() => _handling = true);
    try {
      await _controller.stop();
      if (!mounted) return;
      final code = codes.first;
      final eventId = publicEventIdFromCode(code);
      if (eventId != null) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PublicEventRouteScreen(eventId: eventId),
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF004D40),
            title: Text(
              code.startsWith('EURO_HABESHA_TICKET|')
                  ? 'Billet personnel'
                  : 'QR non reconnu',
              style: const TextStyle(color: _gold),
            ),
            content: Text(
              code.startsWith('EURO_HABESHA_TICKET|')
                  ? 'Pour contrôler une entrée, ouvrez Mes événements, puis Scanner QR dans l’événement concerné. Ce scanner public ne valide aucun billet.'
                  : 'Ce code n’est pas un lien public d’événement Euro Habesha reconnu.',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const AppText(
                  'Scanner à nouveau',
                  style: TextStyle(color: _gold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText('Impossible de lire ce QR : $error')),
        );
    } finally {
      if (mounted) {
        setState(() => _handling = false);
        try {
          await _controller.start();
        } catch (_) {
          // MobileScanner displays camera permission and device errors below.
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      title: const AppText('Scanner un QR code'),
      backgroundColor: _dark,
      foregroundColor: _gold,
      actions: [
        IconButton(
          tooltip: 'Activer ou désactiver la lampe',
          onPressed: () => _controller.toggleTorch(),
          icon: const Icon(Icons.flashlight_on_outlined),
        ),
        IconButton(
          tooltip: 'Changer de caméra',
          onPressed: () => _controller.switchCamera(),
          icon: const Icon(Icons.cameraswitch_outlined),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppText(
                'Caméra indisponible. Vérifiez les autorisations dans les paramètres du téléphone.\n\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold, width: 3),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 56, color: Colors.white54),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _dark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const AppText(
                  'Scannez le QR public d’un événement Euro Habesha pour découvrir l’événement et réserver un billet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
