import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'business_review_policy.dart';

const _gold = Color(0xFFFFD700),
    _green = Color(0xFF061E12),
    _card = Color(0xFF004D40);

/// Reviews belong to an exact public profile, never to a feed summary or dossier.
Future<DocumentReference<Map<String, dynamic>>> _reviewTarget(
  Map<String, dynamic> data,
) async {
  final db = FirebaseFirestore.instance;
  final value = data['docRef'];
  String? path = value is DocumentReference ? value.path : null;
  final source = data['sourceCollection']?.toString();
  final id = data['sourceId']?.toString();
  if (path == null || !isPublicReviewPath(path)) {
    if (source != null && id != null && isPublicReviewPath('$source/$id')) {
      path = '$source/$id';
    } else {
      final original = value is DocumentReference
          ? value.path.split('/')
          : <String>[];
      final sourceCollection =
          original.length == 2 &&
              reviewPublicCollectionForSource(original[0]) != null
          ? original[0]
          : source;
      final sourceId =
          original.length == 2 &&
              reviewPublicCollectionForSource(original[0]) != null
          ? original[1]
          : id;
      final collection = reviewPublicCollectionForSource(sourceCollection);
      if (collection == null ||
          sourceId == null ||
          !RegExp(r'^[A-Za-z0-9_-]{1,150}$').hasMatch(sourceId)) {
        throw StateError(
          'Cette page ne possède pas de référence publique pour les avis. Ouvrez sa fiche depuis Découvrir.',
        );
      }
      final matches = await db
          .collection(collection)
          .where('sourceId', isEqualTo: sourceId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      final exact = matches.docs
          .where((doc) => doc.data()['sourceCollection'] == sourceCollection)
          .toList();
      if (exact.length != 1) {
        throw StateError(
          'Le lien vers la fiche publique doit être vérifié par l’administrateur.',
        );
      }
      path = exact.single.reference.path;
    }
  }
  if (!isPublicReviewPath(path)) {
    throw StateError('Référence publique invalide.');
  }
  final ref = db.doc(path);
  final profile = await ref
      .get(const GetOptions(source: Source.server))
      .timeout(const Duration(seconds: 15));
  if (!profile.exists) throw StateError('Cette fiche publique n’existe plus.');
  return ref;
}

String _reviewError(Object error) {
  if (error is TimeoutException) {
    return 'La confirmation prend trop de temps. Vérifiez votre connexion et la liste des avis avant de réessayer. Une nouvelle tentative remplace votre avis au même endroit.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Envoi refusé (permission-denied). Vérifiez le compte connecté et les règles des avis pour cette fiche. Votre texte est conservé.',
      'unauthenticated' || 'user-token-expired' =>
        'Votre session a expiré. Reconnectez-vous puis réessayez.',
      'unavailable' =>
        'Connexion indisponible. Réessayez lorsque vous êtes connecté.',
      _ => 'Envoi impossible (${error.code}). Votre texte est conservé.',
    };
  }
  return error is StateError
      ? error.message.toString()
      : 'Impossible de charger ou d’envoyer les avis. Réessayez.';
}

Future<void> showBusinessReviewDialog(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connectez-vous avec un compte pour publier un avis.'),
      ),
    );
    return;
  }
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReviewDialog(data: data, uid: user.uid),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.data, required this.uid});
  final Map<String, dynamic> data;
  final String uid;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _text = TextEditingController();
  int _stars = 5;
  bool _sending = false;
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final validation = businessReviewInputError(_stars, _text.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous || user.uid != widget.uid) {
        throw StateError(
          'Le compte connecté a changé. Fermez cette fenêtre puis reconnectez-vous.',
        );
      }
      final target = await _reviewTarget(widget.data);
      await user.getIdToken(true).timeout(const Duration(seconds: 15));
      if (FirebaseAuth.instance.currentUser?.uid != widget.uid) {
        throw StateError(
          'Le compte connecté a changé. Réessayez avec le bon compte.',
        );
      }
      final name = user.displayName?.trim();
      // The UID document makes repeated taps/retries replace the same review.
      // No write to identity, verification, badges or the parent business.
      await target
          .collection('reviews')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'user': name == null || name.isEmpty ? 'Utilisateur' : name,
            'rating': _stars.toStringAsFixed(1),
            'comment': _text.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Votre avis a bien été enregistré. Merci !'),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = _reviewError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: AlertDialog(
      backgroundColor: _card,
      title: const Text('Donner mon avis', style: TextStyle(color: _gold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.data['name']?.toString() ?? 'Professionnel',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  tooltip: '${index + 1} étoile(s)',
                  onPressed: _sending
                      ? null
                      : () => setState(() => _stars = index + 1),
                  icon: Icon(
                    index < _stars ? Icons.star : Icons.star_border,
                    color: _gold,
                  ),
                ),
              ),
            ),
            TextField(
              controller: _text,
              enabled: !_sending,
              minLines: 3,
              maxLines: 5,
              maxLength: 2000,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Votre expérience',
                labelStyle: TextStyle(color: Colors.white70),
                counterStyle: TextStyle(color: Colors.white70),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  semanticsLabel: _error,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _green,
          ),
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Envoi…' : 'Envoyer mon avis'),
        ),
      ],
    ),
  );
}

class BusinessReviewsList extends StatefulWidget {
  const BusinessReviewsList({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  State<BusinessReviewsList> createState() => _BusinessReviewsListState();
}

class _BusinessReviewsListState extends State<BusinessReviewsList> {
  late Future<DocumentReference<Map<String, dynamic>>> _target;
  @override
  void initState() {
    super.initState();
    _target = _reviewTarget(widget.data);
  }

  @override
  void didUpdateWidget(covariant BusinessReviewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data['docRef'] != widget.data['docRef'] ||
        oldWidget.data['sourceId'] != widget.data['sourceId'] ||
        oldWidget.data['sourceCollection'] != widget.data['sourceCollection']) {
      _target = _reviewTarget(widget.data);
    }
  }

  Widget _errorBox(Object error) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _reviewError(error),
        style: const TextStyle(color: Colors.orangeAccent),
      ),
      TextButton(
        onPressed: () => setState(() => _target = _reviewTarget(widget.data)),
        child: const Text('Réessayer'),
      ),
    ],
  );
  Widget _rows(List<Map<String, dynamic>> rows) => Column(
    children: [
      if (rows.isEmpty)
        const Text(
          'Aucun avis pour le moment.',
          style: TextStyle(color: Colors.white70),
        ),
      for (final row in rows)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row['user']?.toString() ?? 'Utilisateur',
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.star, color: _gold, size: 16),
                  Text(
                    ' ${row['rating'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                row['comment']?.toString() ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
    ],
  );
  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<DocumentReference<Map<String, dynamic>>>(
    future: _target,
    builder: (context, snapshot) {
      if (snapshot.hasError) return _errorBox(snapshot.error!);
      if (!snapshot.hasData) return const LinearProgressIndicator(color: _gold);
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: snapshot.data!
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, reviews) {
          if (reviews.hasError) return _errorBox(reviews.error!);
          if (!reviews.hasData) {
            return const LinearProgressIndicator(color: _gold);
          }
          final saved = reviews.data!.docs.map((doc) => doc.data()).toList();
          final uids = saved
              .map((row) => row['userId'])
              .whereType<String>()
              .toSet();
          final legacy = widget.data['reviews'];
          return _rows([
            ...saved,
            if (legacy is List)
              ...legacy
                  .whereType<Map>()
                  .where(
                    (row) =>
                        row['userId'] == null || !uids.contains(row['userId']),
                  )
                  .map((row) => Map<String, dynamic>.from(row)),
          ]);
        },
      );
    },
  );
}
