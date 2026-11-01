import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'banner_destination.dart';
import 'jobs_screen.dart';

Future<void> showJobBanner(
  BuildContext context,
  Map<String, dynamic> banner,
) async {
  const gold = Color(0xFFFFD700);
  const dark = Color(0xFF061E12);
  final id = exactJobBannerId(banner);
  if (id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Le lien de cette publicité doit être corrigé par l’administrateur.',
        ),
      ),
    );
    return;
  }
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dark,
      title: Text(
        (banner['title'] ?? banner['targetName'] ?? 'Offre du professionnel')
            .toString(),
        style: const TextStyle(color: gold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((banner['body'] ?? banner['description'] ?? '')
                .toString()
                .isNotEmpty)
              Text(
                (banner['body'] ?? banner['description']).toString(),
                style: const TextStyle(color: Colors.white),
              ),
            if ((banner['promotion'] ?? banner['discountText'] ?? '')
                .toString()
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  (banner['promotion'] ?? banner['discountText']).toString(),
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if ((banner['promoCode'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SelectableText(
                  'Code : ${banner['promoCode']}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(foregroundColor: gold),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: dark,
          ),
          child: const Text('Voir la fiche'),
        ),
      ],
    ),
  );
  if (open != true || !context.mounted) return;
  try {
    final ref = FirebaseFirestore.instance.collection('jobs').doc(id);
    final snap = await ref.get(const GetOptions(source: Source.server));
    if (!context.mounted) return;
    final raw = snap.data();
    final status = (raw?['status'] ?? '').toString().toLowerCase();
    if (!snap.exists ||
        raw == null ||
        (status.isNotEmpty &&
            !const ['approved', 'published'].contains(status))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette fiche n’est plus disponible.')),
      );
      return;
    }
    final fields = raw['fields'] is Map
        ? Map<String, dynamic>.from(raw['fields'])
        : <String, dynamic>{};
    String first(List<dynamic> values) => values
        .map((value) => value?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final job = <String, dynamic>{
      ...fields,
      ...raw,
      'id': snap.id,
      'docRef': ref,
      'name': first([
        raw['name'],
        fields['title'],
        raw['title'],
        banner['targetName'],
      ]),
      'title': first([
        raw['title'],
        fields['professionTitle'],
        fields['jobCategory'],
        'Prestataire',
      ]),
      'location': first([
        raw['location'],
        fields['cityAddress'],
        fields['city'],
      ]),
      'phone': first([raw['phone'], fields['phone'], fields['phoneNumber']]),
      'email': first([raw['email'], fields['emailAddress'], fields['email']]),
    };
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => JobDetailScreen(jobData: job)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Impossible d’ouvrir cette fiche. Réessayez dans un instant.',
        ),
      ),
    );
  }
}
