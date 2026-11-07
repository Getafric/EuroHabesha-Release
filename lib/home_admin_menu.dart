import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'l10n/app_ui.dart';
import 'etape10/workspace_ui.dart';
import 'professional_photo_cropper.dart';

class HomeAdminMenu extends StatelessWidget {
  const HomeAdminMenu({
    super.key,
    required this.collection,
    required this.id,
    this.title = '',
  });
  final String collection, id, title;
  Future<void> _manage(
    BuildContext context,
    String action,
  ) => ehRun(context, () async {
    if (action == 'edit') {
      final d =
          (await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(id)
                  .get())
              .data();
      if (d == null || !context.mounted) return;
      final f = ehMap(d['fields']);
      await ehOpen<bool>(
        context,
        EhForm(
          title: 'Modifier la fiche',
          photoKey: 'imageUrl',
          photoUse: ProfessionalPhotoUse.cover,
          initial: {
            'title': f['title'] ?? d['title'] ?? d['name'] ?? title,
            'description': f['description'] ?? d['description'] ?? '',
            'imageUrl': f['coverUrl'] ?? d['coverUrl'] ?? d['imageUrl'] ?? '',
          },
          fields: const [
            EhField('title', 'Titre / nom', max: 120),
            EhField('description', 'Description', lines: 5, required: false),
          ],
          save: (v) async {
            final payload = Map<String, dynamic>.from(v);
            final previousPhoto =
                f['coverUrl'] ?? d['coverUrl'] ?? d['imageUrl'] ?? '';
            if (payload['imageUrl'] == previousPhoto)
              payload.remove('imageUrl');
            await ehCall('home.admin', {
              ...payload,
              'operation': 'edit',
              'sourceCollection': collection,
              'sourceId': id,
            });
          },
        ),
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText(
          action == 'hide'
              ? 'Retirer de l’accueil ?'
              : 'Supprimer cette fiche ?',
        ),
        content: AppText(
          action == 'hide' ? 'La fiche restera accessible dans son annuaire.' : 'La fiche et ses aperçus seront retirés. Les commandes et billets restent conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText('Confirmer'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await ehCall('home.admin', {
      'operation': action,
      'sourceCollection': collection,
      'sourceId': id,
    });
  });
  @override
  Widget build(BuildContext context) =>
      !AppSession.isSuperAdmin || collection.isEmpty || id.isEmpty
      ? const SizedBox.shrink()
      : PopupMenuButton<String>(
          tooltip: ui(context, 'Gérer cette fiche'),
          icon: const Icon(Icons.more_horiz, color: ehGold),
          onSelected: (action) => _manage(context, action),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: AppText(ui(context, 'Modifier la fiche')),
            ),
            PopupMenuItem(
              value: 'hide',
              child: AppText(ui(context, 'Retirer de l’accueil')),
            ),
            PopupMenuItem(
              value: 'delete',
              child: AppText(ui(context, 'Supprimer la fiche')),
            ),
          ],
        );
}
