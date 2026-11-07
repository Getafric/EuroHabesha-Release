import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'admin_submission_workflow.dart';
import 'admin_professional_verification_review_screen.dart';

/// Reads the existing private documents by their exact path. No collection-group
/// query, public copy of documents, new write, or new review authority is added.
class AdminPrivateVerificationInbox extends StatefulWidget {
  const AdminPrivateVerificationInbox({super.key});
  @override
  State<AdminPrivateVerificationInbox> createState() =>
      _AdminPrivateVerificationInboxState();
}

class _AdminPrivateVerificationInboxState
    extends State<AdminPrivateVerificationInbox> {
  static const _dark = Color(0xFF061E12),
      _green = Color(0xFF004D40),
      _gold = Color(0xFFFFD700);
  static const _pageSize = 100;
  final _db = FirebaseFirestore.instance;
  final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> _cursors = {};
  final Set<String> _finished = {};
  final Map<String, _PrivateReviewEntry> _entries = {};
  final Map<String, String> _errors = {};
  bool _loading = false;
  bool _showDrafts = false;
  int _scanned = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  String _failure(Object error) =>
      error is FirebaseException ? error.code : 'connexion indisponible';

  Future<void> _load({bool reset = false}) async {
    if (_loading || !AppSession.isSuperAdmin) {
      return;
    }
    setState(() {
      _loading = true;
      _errors.clear();
      if (reset) {
        _cursors.clear();
        _finished.clear();
        _entries.clear();
        _scanned = 0;
      }
    });
    try {
      for (final source in adminPrivateReviewSources) {
        if (_finished.contains(source)) {
          continue;
        }
        try {
          Query<Map<String, dynamic>> query = _db
              .collection(source)
              .orderBy(FieldPath.documentId)
              .limit(_pageSize);
          final cursor = _cursors[source];
          if (cursor != null) {
            query = query.startAfterDocument(cursor);
          }
          final page = await query.get().timeout(const Duration(seconds: 20));
          if (!mounted || !AppSession.isSuperAdmin) {
            return;
          }
          var completePage = true;
          // Bound concurrent private reads. A denied read is surfaced, never
          // interpreted as an empty or missing verification request.
          for (var offset = 0; offset < page.docs.length; offset += 8) {
            final batch = page.docs.skip(offset).take(8);
            await Future.wait(
              batch.map((parent) async {
                try {
                  final private = await parent.reference
                      .collection('verification')
                      .doc('professional')
                      .get()
                      .timeout(const Duration(seconds: 20));
                  if (!mounted || !AppSession.isSuperAdmin || !private.exists) {
                    return;
                  }
                  final data = private.data() ?? <String, dynamic>{};
                  final fields = parent.data()['fields'];
                  final title =
                      (fields is Map ? fields['title'] : null) ??
                      data['legalName'] ??
                      parent.id;
                  _entries['$source/${parent.id}'] = _PrivateReviewEntry(
                    source,
                    parent.id,
                    title.toString(),
                    data,
                  );
                } catch (error) {
                  completePage = false;
                  _errors[source] =
                      'Lecture du dossier privé : ${_failure(error)}. Actualisez pour réessayer.';
                }
              }),
            );
            if (!mounted || !AppSession.isSuperAdmin) {
              return;
            }
          }
          _scanned += page.docs.length;
          // Do not advance beyond a page containing failed reads.
          if (completePage) {
            if (page.docs.isNotEmpty) {
              _cursors[source] = page.docs.last;
            }
            if (page.docs.length < _pageSize) {
              _finished.add(source);
            }
          }
        } catch (error) {
          _errors[source] =
              'Lecture des fiches : ${_failure(error)}. Actualisez pour réessayer.';
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(_PrivateReviewEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProfessionalVerificationReviewScreen(
          sourceCollection: entry.source,
          businessId: entry.id,
        ),
      ),
    );
    if (mounted) {
      await _load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = AppSession.isSuperAdmin;
    final entries = _entries.values
        .where(
          (entry) =>
              _showDrafts || adminPrivateReviewPending(entry.data['status']),
        )
        .toList();
    entries.sort((a, b) {
      final aStamp = a.data['submittedAt'], bStamp = b.data['submittedAt'];
      final aTime = aStamp is Timestamp ? aStamp.millisecondsSinceEpoch : 0;
      final bTime = bStamp is Timestamp ? bStamp.millisecondsSinceEpoch : 0;
      return bTime.compareTo(aTime);
    });
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: _gold,
        title: const AppText('Dossiers privés professionnels'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading || !allowed ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !allowed
          ? const Center(
              child: AppText(
                'Réservé au Super Admin.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppText(
                  'Fiches publiques et dossiers d’identité sont examinés séparément.',
                  style: TextStyle(color: Colors.white70),
                ),
                SwitchListTile(
                  value: _showDrafts,
                  activeThumbColor: _gold,
                  title: const AppText(
                    'Afficher aussi brouillons et dossiers traités',
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) => setState(() => _showDrafts = value),
                ),
                if (_loading) const LinearProgressIndicator(color: _gold),
                AppText(
                  '$_scanned fiches parcourues · ${entries.length} dossiers affichés',
                  style: const TextStyle(color: Colors.white70),
                ),
                for (final error in _errors.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AppText(
                      '${error.key} : ${error.value}',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                if (!_loading && entries.isEmpty)
                  Text(
                    _finished.length == adminPrivateReviewSources.length &&
                            _errors.isEmpty
                        ? 'Aucun dossier correspondant trouvé.'
                        : 'Aucun dossier trouvé dans les pages lues. Continuez le chargement ou corrigez les erreurs affichées.',
                    style: const TextStyle(color: Colors.white),
                  ),
                for (final entry in entries)
                  Card(
                    color: _green,
                    child: ListTile(
                      title: Text(
                        entry.title,
                        style: const TextStyle(color: _gold),
                      ),
                      subtitle: AppText(
                        '${entry.source} · ${entry.data['status'] ?? 'draft'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.folder_open_outlined,
                        color: _gold,
                      ),
                      onTap: _loading ? null : () => _open(entry),
                    ),
                  ),
                if (_finished.length < adminPrivateReviewSources.length)
                  FilledButton(
                    onPressed: _loading ? null : () => _load(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _dark,
                    ),
                    child: const AppText('Charger la suite / Réessayer'),
                  ),
                const SizedBox(height: 12),
                const AppText(
                  'La liste est chargée par pages de 100 fiches par source. Actualisez après un nouvel envoi. '
                  'Une fiche employeur seule se trouve dans Soumissions, pas dans les justificatifs privés.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
    );
  }
}

class _PrivateReviewEntry {
  const _PrivateReviewEntry(this.source, this.id, this.title, this.data);
  final String source, id, title;
  final Map<String, dynamic> data;
}
