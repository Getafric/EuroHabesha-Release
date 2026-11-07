import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'etape10/workspace_ui.dart';
import 'l10n/app_ui.dart';
import 'professional_photo_cropper.dart';

/// Remote presentation images only. No bundled example photo is required.
class EhIllustrationPhoto extends StatelessWidget {
  const EhIllustrationPhoto({super.key, this.url = '', required this.icon});
  final String url;
  final IconData icon;

  Widget _placeholder() => ColoredBox(
    color: const Color(0xFF004D40),
    child: Center(child: Icon(icon, size: 52, color: const Color(0xFFFFD700))),
  );

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return _placeholder();
    }
    return Image.network(
      url.trim(),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }
}

/// Shared travel banner, edited using the existing administrator photo form.
class EhManagedTravelBanner extends StatelessWidget {
  const EhManagedTravelBanner({super.key, this.height = 125});
  final double height;

  static DocumentReference<Map<String, dynamic>> get _config =>
      FirebaseFirestore.instance.collection('platformSettings')
          .doc('homeCommunityExamples');

  Future<void> _edit(BuildContext context, String imageUrl) async {
    if (!AppSession.isSuperAdmin) return;
    await ehRun(context, () async {
      await ehOpen<bool>(context, EhForm(
        title: 'Ajouter / changer la photo',
        photoKey: 'imageUrl',
        photoUse: ProfessionalPhotoUse.cover,
        initial: {'imageUrl': imageUrl},
        fields: const [],
        save: (values) async {
          if (!AppSession.isSuperAdmin) {
            throw const FormatException('Action non autorisée.');
          }
          await _config.set({
            'cards': {'travel': {'imageUrl': values['imageUrl'] ?? ''}},
          }, SetOptions(merge: true));
        },
      ));
    });
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _config.snapshots(),
        builder: (context, snapshot) {
          final cards = ehMap(snapshot.data?.data()?['cards']);
          final imageUrl = '${ehMap(cards['travel'])['imageUrl'] ?? ''}';
          return SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              EhIllustrationPhoto(url: imageUrl, icon: Icons.flight),
              if (AppSession.isSuperAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(24),
                    child: PopupMenuButton<String>(
                      tooltip: ui(context, 'Ajouter / changer la photo'),
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onSelected: (action) {
                        if (!AppSession.isSuperAdmin) return;
                        if (action == 'edit') {
                          _edit(context, imageUrl);
                        } else if (action == 'remove') {
                          ehRun(context, () async {
                            if (!AppSession.isSuperAdmin) return;
                            await _config.set({
                              'cards': {'travel': {'imageUrl': ''}},
                            }, SetOptions(merge: true));
                          });
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit',
                          child: AppText('Ajouter / changer la photo')),
                        if (imageUrl.isNotEmpty)
                          const PopupMenuItem(value: 'remove',
                            child: AppText('Retirer la photo')),
                      ],
                    ),
                  ),
                ),
            ]),
          );
        },
      );
}
