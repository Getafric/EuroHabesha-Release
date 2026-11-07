import 'l10n/app_ui.dart';
// EH_MODERATION_MATERIAL_V1
import 'professional_moderation_surface.dart';
import 'admin_professional_verification_review_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'services/nearby_sync_service.dart';

/// Écran de modération des établissements et professionnels.
/// IMPORTANT: les règles Firestore doivent valider les droits administrateur.
class AdminProfessionalModerationScreen extends StatefulWidget {
  const AdminProfessionalModerationScreen({super.key});

  @override
  State<AdminProfessionalModerationScreen> createState() =>
      _AdminProfessionalModerationScreenState();
}

class _AdminProfessionalModerationScreenState
    extends State<AdminProfessionalModerationScreen> {
  static const _dark = Color(0xFF061E12);
  static const _green = Color(0xFF004D40);
  static const _gold = Color(0xFFFFD700);
  static const _collections = <String, String>{
    'businessSubmissions': 'Établissements soumis',
    'jobSubmissions': 'Services soumis',
    'businesses': 'Établissements publiés',
    'jobs': 'Professionnels publiés',
  };
  String _selectedCollection = 'businessSubmissions';
  bool _busy = false;

  Future<void> _message(String message) async {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(backgroundColor: _green, content: Text(message)));
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _green,
            title: Text(title, style: const TextStyle(color: _gold)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const AppText(
                  'Annuler',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _dark,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const AppText('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _moderate(
    DocumentReference<Map<String, dynamic>> ref,
    String action,
  ) async {
    if (_busy || !['published', 'suspended'].contains(action)) {
      return;
    }
    final sourceCollection = ref.parent.id;
    final isPublicCollection =
        sourceCollection == 'businesses' || sourceCollection == 'jobs';
    if (!await _confirm(
      action == 'published'
          ? 'Publier cette fiche ?'
          : 'Suspendre cette fiche ?',
      'Cette action modifie la publication. La vérification du dossier est gérée séparément.',
    )) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final changes = <String, dynamic>{
        'status': action,
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': AppSession.email,
      };
      batch.update(ref, changes);
      // Keep publication/Nearby handling separate from the private dossier.
      if (isPublicCollection) {
        final snapshot = await ref.get();
        if (!snapshot.exists) {
          await _message('La fiche publique est introuvable.');
          return;
        }
        NearbySyncService(FirebaseFirestore.instance).stageUpsert(
          batch,
          sourceCollection: sourceCollection,
          sourceId: ref.id,
          publicData: <String, dynamic>{...?snapshot.data(), ...changes},
        );
      }
      await batch.commit();
      await _message('Publication enregistrée : $action');
    } catch (error) {
      await _message('Échec de la modification : $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const ColoredBox(
        color: _dark,
        child: Center(
          child: AppText(
            'Accès administrateur requis',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return ProfessionalModerationSurface(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppText(
                'Modération professionnelle',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: _gold, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCollection,
              dropdownColor: _green,
              decoration: const InputDecoration(
                labelText: 'Afficher',
                labelStyle: TextStyle(color: _gold),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _gold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _gold),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              items: _collections.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCollection = value);
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(_selectedCollection)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: AppText(
                      'Erreur de lecture : ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _gold),
                  );
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: AppText(
                      'Aucune fiche pour cette catégorie',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final fields = data['fields'] is Map
                        ? data['fields'] as Map
                        : const {};
                    final name =
                        (data['name'] ??
                                data['title'] ??
                                data['businessName'] ??
                                fields['title'] ??
                                'Sans nom')
                            .toString();
                    final status = (data['status'] ?? 'pending').toString();
                    final verified = data['isVerified'] == true;
                    return Card(
                      color: _green,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              'Publication : $status  •  Vérifié : ${verified ? "Oui" : "Non"}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            const AppText(
                              'Le dossier professionnel est consulté sur la fiche d’origine.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _gold,
                                  foregroundColor: _dark,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              AdminProfessionalVerificationReviewScreen(
                                                sourceCollection:
                                                    doc.reference.parent.id,
                                                businessId: doc.id,
                                              ),
                                        ),
                                      ),
                                icon: const Icon(Icons.folder_open_outlined),
                                label: const AppText(
                                  'Examiner le dossier professionnel',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _moderate(
                                          doc.reference,
                                          'published',
                                        ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _gold,
                                    side: const BorderSide(color: _gold),
                                  ),
                                  child: const AppText('Publier'),
                                ),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _moderate(
                                          doc.reference,
                                          'suspended',
                                        ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  child: const AppText('Suspendre'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
