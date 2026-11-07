import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/nearby_sync_service.dart';

/// Écran d'administration autonome : audit puis reconstruction de l'index Nearby.
/// Aucun document source, billet ou paiement n'est modifié.
/// À ouvrir UNIQUEMENT depuis un espace administrateur autorisé.
class AdminNearbyBackfillScreen extends StatefulWidget {
  const AdminNearbyBackfillScreen({super.key});

  @override
  State<AdminNearbyBackfillScreen> createState() =>
      _AdminNearbyBackfillScreenState();
}

class _AdminNearbyBackfillScreenState extends State<AdminNearbyBackfillScreen> {
  static const _sources = [
    'businesses',
    'events',
    'marketplace',
    'jobs',
    'posts',
  ];
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _busy = false;
  bool _audited = false;
  int _eligible = 0;
  int _ignored = 0;
  int _synced = 0;
  String _message = 'Commencez par vérifier les publications existantes.';
  final Map<String, int> _counts = {};

  bool _eligibleDoc(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status != 'published' && status != 'approved') {
      return false;
    }
    if (data['isDemo'] == true ||
        data['isDeleted'] == true ||
        data['deleted'] == true ||
        data['archived'] == true ||
        data['isActive'] == false) {
      return false;
    }
    final fields = data['fields'] is Map ? data['fields'] as Map : const {};
    final city = [
      data['city'],
      data['ville'],
      fields['city'],
      fields['ville'],
    ].whereType<String>().any((s) => s.trim().isNotEmpty);
    final geo = data['publicLocation'];
    final hasPublicGeo =
        geo is Map &&
        (geo['latitude'] ?? geo['lat']) is num &&
        (geo['longitude'] ?? geo['lng']) is num;
    // Évite de créer des fiches Nearby sans ville ni position publique.
    return city || hasPublicGeo;
  }

  Future<bool> _checkAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    // Même critère que les règles Firestore du projet : admins/{uid}
    // ou compte Super Admin. Les règles restent la protection réelle.
    if (user.email == 'getafricshow1@gmail.com') {
      return true;
    }
    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.exists;
  }

  Future<void> _run({required bool apply}) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = apply ? 'Synchronisation en cours…' : 'Analyse en cours…';
      if (!apply) {
        _audited = false;
      }
      _eligible = 0;
      _ignored = 0;
      _synced = 0;
      _counts.clear();
    });
    try {
      if (!await _checkAdmin()) {
        throw StateError('Accès réservé aux administrateurs principaux.');
      }
      final sync = NearbySyncService(_db);
      for (final collection in _sources) {
        int count = 0;
        // Pagination pour ne pas charger toutes les publications en mémoire.
        DocumentSnapshot<Map<String, dynamic>>? last;
        while (true) {
          Query<Map<String, dynamic>> query = _db
              .collection(collection)
              .orderBy(FieldPath.documentId)
              .limit(100);
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          final page = await query.get();
          if (page.docs.isEmpty) {
            break;
          }
          for (final doc in page.docs) {
            final data = doc.data();
            if (!_eligibleDoc(data)) {
              _ignored++;
              continue;
            }
            count++;
            _eligible++;
            if (apply) {
              // ID stable : businesses_ID, events_ID, etc. => pas de doublon.
              final batch = _db.batch();
              sync.stageUpsert(
                batch,
                sourceCollection: collection,
                sourceId: doc.id,
                publicData: data,
              );
              await batch.commit();
              _synced++;
            }
          }
          last = page.docs.last;
          if (mounted) {
            setState(
              () => _message =
                  '$collection : $count publication(s) admissible(s) analysée(s)…',
            );
          }
          if (page.docs.length < 100) {
            break;
          }
        }
        _counts[collection] = count;
      }
      if (mounted) {
        setState(() {
          _audited = true;
          _message = apply
              ? 'Terminé : $_synced fiche(s) Nearby mises à jour.'
              : 'Analyse terminée : $_eligible publication(s) admissible(s), $_ignored ignorée(s).';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _message =
              'Opération interrompue : $e. Les fiches déjà traitées restent enregistrées ; relancer est sans doublon.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF061E12);
    const gold = Color(0xFFFFD700);
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Administration · À proximité'),
        backgroundColor: green,
        foregroundColor: gold,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppText(
            'Étape 6 — Anciennes publications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const AppText(
            'Analyse les contenus déjà publiés, puis crée ou actualise leur fiche dans nearbyItems. Aucun événement, ticket, paiement ni document source n’est modifié.',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : () => _run(apply: false),
            icon: const Icon(Icons.fact_check_outlined),
            label: const AppText('1. Analyser les publications'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busy || !_audited || _eligible == 0
                ? null
                : () => _run(apply: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: gold,
            ),
            icon: const Icon(Icons.sync),
            label: const AppText('2. Synchroniser avec À proximité'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 18),
          Text(_message),
          const SizedBox(height: 12),
          ..._counts.entries.map(
            (entry) => ListTile(
              dense: true,
              title: Text(entry.key),
              trailing: AppText('${entry.value}'),
            ),
          ),
          const SizedBox(height: 16),
          const AppText(
            'Note : les contenus sans ville ni localisation publique sont ignorés. Les anciennes fiches Nearby orphelines ne sont pas supprimées automatiquement.',
          ),
        ],
      ),
    );
  }
}
