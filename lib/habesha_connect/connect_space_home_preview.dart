import 'home_community_examples.dart';
import '../home_admin_menu.dart';
import '../l10n/app_ui.dart';
import '../discovery_photo.dart';
import '../member_interface_text.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'connect_space_pages.dart';
import 'connect_space_service.dart';

/// One home module: real published spaces plus the signed-in owner's requests.
class ConnectSpaceHomePreview extends StatelessWidget {
  const ConnectSpaceHomePreview({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: connectGold),
              const SizedBox(width: 8),
              const Expanded(
                child: AppText(
                  'Habesha Connect',
                  style: TextStyle(
                    color: connectGold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpen,
                child: const AppText(
                  'Voir tout',
                  style: TextStyle(color: connectGold),
                ),
              ),
            ],
          ),
          Text(
            memberText(
              context,
              'Groupes, associations et discussions près de vous.',
              'Groups, associations and discussions near you.',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ConnectSpaceService.spaces
                .where('status', isEqualTo: 'published')
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return connectNotice('Espaces momentanément indisponibles.');
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(color: connectGold),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              final visibleDocs = docs
                  .where(
                    (d) =>
                        d.data()['homeHidden'] != true &&
                        d.data()['isDeleted'] != true,
                  )
                  .toList();
              if (visibleDocs.isEmpty) return const HomeCommunityExamples();
              return SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final doc = visibleDocs[index];
                    final data = doc.data();
                    final logo = data['logoUrl'];
                    return SizedBox(
                      width: 185,
                      child: Card(
                        color: connectGreen,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConnectSpaceDetail(id: doc.id),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 100,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    DiscoveryPhoto(
                                      urls: logo is String && logo.isNotEmpty
                                          ? [logo]
                                          : const <String>[],
                                      fallback: const Center(
                                        child: Icon(
                                          Icons.groups_outlined,
                                          color: connectGold,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: HomeAdminMenu(
                                        collection: 'connectSpaces',
                                        id: doc.id,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (data['title'] ?? '').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: connectGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      data['kind'] == 'association'
                                          ? 'Association'
                                          : memberText(
                                              context,
                                              'Groupe',
                                              'Group',
                                            ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      (data['city'] ?? '').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (user != null && !user.isAnonymous)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ConnectSpaceService.requests
                  .where('ownerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return connectNotice(
                    'Suivi des demandes indisponible : ${snapshot.error}',
                  );
                }
                final waiting = (snapshot.data?.docs ?? [])
                    .where((doc) => doc.data()['status'] != 'approved')
                    .take(5)
                    .toList();
                return Column(
                  children: [
                    for (final doc in waiting)
                      Card(
                        color: connectGreen,
                        child: ListTile(
                          leading: const Icon(
                            Icons.assignment_outlined,
                            color: connectGold,
                          ),
                          title: Text(
                            (doc.data()['title'] ?? '').toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            doc.data()['status'] == 'approved'
                                ? 'Mon espace publié — gérer'
                                : doc.data()['status'] == 'rejected'
                                ? 'Demande refusée — voir le motif'
                                : 'Votre demande est en cours d’examen',
                            style: const TextStyle(color: connectGold),
                          ),
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => doc.data()['status'] == 'approved'
                                  ? ConnectSpaceDetail(id: doc.id)
                                  : const ConnectMyRequests(),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
