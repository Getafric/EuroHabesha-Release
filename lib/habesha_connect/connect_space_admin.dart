import '../l10n/app_ui.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:printing/printing.dart';

import '../etape10/workspace_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_session.dart';
import 'connect_space_model.dart';
import 'connect_space_pages.dart';
import 'connect_space_service.dart';

class ConnectSpaceAdmin extends StatefulWidget {
  const ConnectSpaceAdmin({super.key});
  @override
  State<ConnectSpaceAdmin> createState() => _ConnectSpaceAdminState();
}

class _ConnectSpaceAdminState extends State<ConnectSpaceAdmin> {
  String? _busy;
  Future<void> _review(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool approve,
  ) async {
    if (_busy != null) {
      return;
    }
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: connectGreen,
        title: Text(
          approve ? 'Publier cet espace ?' : 'Refuser cette demande ?',
          style: const TextStyle(color: connectGold),
        ),
        content: approve
            ? const AppText(
                'Vérifiez la présentation et, pour une association, la cohérence du nom officiel '
                'et du numéro déclaré. La publication n’attribue aucun badge d’identité.',
                style: TextStyle(color: Colors.white),
              )
            : TextField(
                controller: note,
                maxLength: 1000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: ui(context, 'Motif du refus'),
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (!approve && note.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const AppText(
              'Confirmer',
              style: TextStyle(color: connectGold),
            ),
          ),
        ],
      ),
    );
    final reason = note.text.trim();
    note.dispose();
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = doc.id);
    try {
      await ConnectSpaceService.review(doc.id, approve: approve, note: reason);
    } catch (error) {
      if (mounted) {
        connectMessage(context, 'Examen impossible : $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: connectDark,
    appBar: AppBar(
      backgroundColor: connectDark,
      foregroundColor: connectGold,
      title: const AppText('Groupes et associations proposés'),
    ),
    body: !AppSession.isSuperAdmin
        ? connectNotice('Accès réservé au Super Admin.')
        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ConnectSpaceService.requests
                .where('status', isEqualTo: 'pendingApproval')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return connectNotice('Lecture impossible : ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: connectGold),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return connectNotice('Aucune demande en attente.');
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  return Card(
                    color: connectGreen,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppText(
                            '${ui(context, connectSpaceLabel(data['kind'].toString()))} — ${data['title']}',
                            style: const TextStyle(
                              color: connectGold,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((data['logoUrl'] ?? '').toString().isNotEmpty)
                            SizedBox(
                              height: 110,
                              child: Image.network(
                                data['logoUrl'].toString(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: connectGold,
                                ),
                              ),
                            ),
                          for (final key in [
                            'description',
                            'topic',
                            'audience',
                            'city',
                            'country',
                            'contactName',
                            'contactPhone',
                            'contactEmail',
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: AppText(
                                '${_labels[key]} : ${data[key] ?? ''}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          if (data['kind'] == 'association') ...[
                            if ('${data['evidencePath'] ?? ''}'.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.description),
                                label: const AppText(
                                  'Ouvrir le justificatif privé',
                                ),
                                onPressed: () => ehRun(context, () async {
                                  final path = data['evidencePath'].toString();
                                  final bytes = await FirebaseStorage.instance
                                      .ref(path)
                                      .getData(8 * 1024 * 1024);
                                  if (bytes == null || !context.mounted) return;
                                  await ehOpen<void>(
                                    context,
                                    EhScaffold(
                                      title: 'Justificatif privé',
                                      body: path.endsWith('.pdf')
                                          ? PdfPreview(
                                              build: (_) async => bytes,
                                              allowPrinting: false,
                                              allowSharing: false,
                                            )
                                          : InteractiveViewer(
                                              child: Center(
                                                child: Image.memory(bytes),
                                              ),
                                            ),
                                    ),
                                  );
                                }),
                              ),
                            AppText(
                              'Nom officiel : ${data['legalName']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            AppText(
                              'Numéro déclaré (à contrôler) : ${data['registrationNumber']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: [
                              FilledButton(
                                onPressed: _busy != null
                                    ? null
                                    : () => _review(doc, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: connectGold,
                                  foregroundColor: connectDark,
                                ),
                                child: const AppText('Approuver et publier'),
                              ),
                              TextButton(
                                onPressed: _busy != null
                                    ? null
                                    : () => _review(doc, false),
                                child: const AppText(
                                  'Refuser',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
  );
  static const _labels = {
    'description': 'Présentation',
    'topic': 'Thème',
    'audience': 'Public concerné',
    'city': 'Ville',
    'country': 'Pays',
    'contactName': 'Responsable privé',
    'contactPhone': 'Téléphone privé',
    'contactEmail': 'E-mail privé',
  };
}
