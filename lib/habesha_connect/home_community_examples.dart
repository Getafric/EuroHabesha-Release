import '../managed_illustration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_session.dart';
import '../l10n/app_ui.dart';
import '../etape10/workspace_ui.dart';
import '../professional_photo_cropper.dart';
import 'connect_space_pages.dart';

/// Clearly marked illustration cards. No account, membership or public group is
/// invented. The administrator controls each example in platformSettings.
class HomeCommunityExamples extends StatelessWidget {
  const HomeCommunityExamples({super.key});
  static final _config = FirebaseFirestore.instance
      .collection('platformSettings')
      .doc('homeCommunityExamples');
  Future<void> _edit(BuildContext context, String id, EhData values) async {
    if (!AppSession.isSuperAdmin) return;
    await ehRun(context, () async {
      await ehOpen<bool>(
        context,
        EhForm(
          title: 'Modifier cet exemple',
          photoKey: 'imageUrl',
          photoUse: ProfessionalPhotoUse.cover,
          initial: {
            'title': values['title'],
            'imageUrl': values['imageUrl'] ?? '',
            'enabled': values['enabled'] != false,
          },
          fields: const [
            EhField('title', 'Titre / nom', max: 120),
            EhField('enabled', 'Afficher cet exemple', toggle: true),
          ],
          save: (v) async {
            if (!AppSession.isSuperAdmin) return;
            await _config.set({
              'cards': {id: v},
            }, SetOptions(merge: true));
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _config.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const SizedBox(height: 80);
          final cards = ehMap(snapshot.data?.data()?['cards']);
          final defaults = <String, EhData>{
            'sport': {
              'title': 'Sport et amis',
              'kind': 'group',
            },
            'culture': {
              'title': 'Culture et entraide',
              'kind': 'association',
            },
          };
          final visible = defaults.entries
              .where((e) => ehMap(cards[e.key])['enabled'] != false)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visible.isNotEmpty)
                SizedBox(
                  height:
                      158 +
                      MediaQuery.textScalerOf(context).scale(14) * 2.4 +
                      MediaQuery.textScalerOf(context).scale(11) * 1.5,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final e = visible[i],
                          v = {...e.value, ...ehMap(cards[e.key])};
                      return SizedBox(
                        width: 190,
                        child: Card(
                          color: const Color(0xFF004D40),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => ehOpen<void>(
                              context,
                              ConnectSpaceDirectory(kind: v['kind']),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 115,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      EhIllustrationPhoto(
                                        url: '${v['imageUrl'] ?? ''}',
                                        icon: e.key == 'sport'
                                            ? Icons.sports_soccer
                                            : Icons.groups,
                                      ),
                                      const Positioned(
                                        left: 6,
                                        top: 6,
                                        child: Chip(
                                          label: AppText('Exemple'),
                                          backgroundColor: Color(0xFFFFD700),
                                          labelStyle: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (AppSession.isSuperAdmin)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_horiz,
                                              color: Colors.white,
                                            ),
                                            onSelected: (action) {
                                              if (!AppSession.isSuperAdmin) return;
                                              if (action == 'edit') {
                                                _edit(context, e.key, v);
                                              } else if (action == 'remove_photo') {
                                                ehRun(context, () async {
                                                  if (!AppSession.isSuperAdmin) return;
                                                  await _config.set({
                                                    'cards': {e.key: {'imageUrl': ''}},
                                                  }, SetOptions(merge: true));
                                                });
                                              } else {
                                                ehRun(context, () async {
                                                  await _config.set({
                                                    'cards': {
                                                      e.key: {'enabled': false},
                                                    },
                                                  }, SetOptions(merge: true));
                                                });
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: AppText(
                                                  'Modifier cet exemple',
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'remove_photo',
                                                child: AppText('Retirer la photo'),
                                              ),
                                              PopupMenuItem(
                                                value: 'hide',
                                                child: AppText(
                                                  'Retirer de l’accueil',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: AppText(
                                    v['title'],
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: AppText(
                                    'Illustration de la communauté',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (visible.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: AppText(
                    'Exemples de présentation, pas de groupes déjà créés.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              if (AppSession.isSuperAdmin && visible.isEmpty)
                TextButton(
                  onPressed: () => ehRun(context, () async {
                    await _config.set({
                      'cards': {
                        'sport': {'enabled': true},
                        'culture': {'enabled': true},
                      },
                    }, SetOptions(merge: true));
                  }),
                  child: const AppText('Réafficher les exemples'),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => ehOpen<void>(
                  context,
                  const ConnectSpaceDirectory(kind: 'group'),
                ),
                icon: const Icon(Icons.add),
                label: const AppText('Créer un groupe'),
              ),
              OutlinedButton(
                onPressed: () => ehOpen<void>(
                  context,
                  const ConnectSpaceDirectory(kind: 'association'),
                ),
                child: const AppText('Présenter une association'),
              ),
            ],
          );
        },
      );
}
