import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_session.dart';

/// Both admin entry points resolve and review the same original dossier.
class AdminProfessionalVerificationReviewScreen extends StatefulWidget {
  const AdminProfessionalVerificationReviewScreen({
    super.key,
    required this.sourceCollection,
    required this.businessId,
  });
  final String sourceCollection;
  final String businessId;
  @override
  State<AdminProfessionalVerificationReviewScreen> createState() =>
      _AdminProfessionalVerificationReviewScreenState();
}

class _AdminProfessionalVerificationReviewScreenState
    extends State<AdminProfessionalVerificationReviewScreen> {
  static const dark = Color(0xFF061E12);
  static const green = Color(0xFF004D40);
  static const gold = Color(0xFFFFD700);
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  Map<String, dynamic> get _target => {
    'sourceCollection': widget.sourceCollection,
    'businessId': widget.businessId,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _failure(Object error) => error is FirebaseFunctionsException
      ? error.message ?? 'Lecture impossible. Actualisez le dossier.'
      : 'Connexion indisponible. Réessayez.';

  Future<void> _load() async {
    if (!AppSession.isSuperAdmin) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Réservé au Super Admin.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    try {
      final result = await _functions
          .httpsCallable('getProfessionalVerificationReview')
          .call<Map<String, dynamic>>(_target);
      if (!mounted) {
        return;
      }
      final data = Map<String, dynamic>.from(result.data);
      if (data['fingerprint'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(data['fingerprint'] as String)) {
        throw StateError('Réponse incompatible.');
      }
      setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _failure(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _message(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: green));
  }

  Future<void> _document(Map<String, dynamic> attachment) async {
    final value = attachment['url'];
    final uri = value is String ? Uri.tryParse(value) : null;
    if (attachment['available'] != true ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'firebasestorage.googleapis.com' ||
        uri.userInfo.isNotEmpty) {
      _message(
        'Ce document ne possède pas de lien reconnu. Demandez un nouveau dépôt.',
      );
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _message('Impossible d’ouvrir le document.');
      }
    } catch (_) {
      _message('Impossible d’ouvrir le document.');
    }
  }

  Future<void> _review(String action) async {
    if (_busy || _data == null) {
      return;
    }
    final approval = action == 'approve' || action == 'synchronize';
    final name = (_data!['businessName'] ?? 'Cet établissement').toString();
    var note = '';
    var checked = false;
    final title = switch (action) {
      'approve' => 'Approuver le dossier professionnel ?',
      'synchronize' => 'Synchroniser l’approbation ?',
      'revoke' => 'Retirer la vérification ?',
      _ => 'Refuser ce dossier ?',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          backgroundColor: green,
          title: Text(title, style: const TextStyle(color: gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Le dossier d’origine, les fiches publiques liées et les index existants '
                  'seront mis à jour ensemble. Aucun paiement réel ne sera activé.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                if (approval)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: checked,
                    activeColor: gold,
                    checkColor: dark,
                    title: const Text(
                      'J’ai contrôlé les informations et les documents du dossier.',
                      style: TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) => update(() => checked = value == true),
                  ),
                if (!approval)
                  TextField(
                    maxLength: 600,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Motif obligatoire',
                      labelStyle: TextStyle(color: gold),
                      counterStyle: TextStyle(color: Colors.white70),
                    ),
                    onChanged: (value) => update(() => note = value),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: dark,
              ),
              onPressed: (approval ? checked : note.trim().length >= 5)
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
    final reason = note.trim();
    if (!mounted || confirmed != true || _data == null) {
      return;
    }
    final payload = <String, dynamic>{
      ..._target,
      'action': action,
      'expectedFingerprint': _data!['fingerprint'],
      'note': reason,
      'confirmedDocuments': approval,
    };
    setState(() => _busy = true);
    try {
      await _functions
          .httpsCallable('reviewProfessionalVerification')
          .call<Map<String, dynamic>>(payload);
      if (!mounted) {
        return;
      }
      _message(
        action == 'revoke'
            ? 'Vérification retirée des fiches liées.'
            : approval
            ? 'Approbation enregistrée et fiches liées synchronisées.'
            : 'Dossier refusé. Le professionnel pourra le corriger.',
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _message(
        '${_failure(error)} Actualisez pour confirmer le statut avant de réessayer.',
      );
      await _load();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _line(String title, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: SelectableText(
      '$title : ${value == null || value.toString().isEmpty ? 'Non renseigné' : value}',
      style: const TextStyle(color: Colors.white70, height: 1.4),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dark,
    appBar: AppBar(
      backgroundColor: dark,
      foregroundColor: gold,
      title: const Text('Dossier professionnel d’origine'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _busy || _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: gold))
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(color: gold),
                    ),
                  ),
                ],
              ),
            ),
          )
        : _data == null
        ? const SizedBox.shrink()
        : _body(_data!),
  );

  Widget _body(Map<String, dynamic> data) {
    final info = data['info'] is Map
        ? Map<String, dynamic>.from(data['info'] as Map)
        : <String, dynamic>{};
    final missing = data['missing'] is List
        ? (data['missing'] as List).map((v) => v.toString()).toList()
        : <String>[];
    final attachments = data['attachments'] is List
        ? (data['attachments'] as List)
              .whereType<Map>()
              .map((v) => Map<String, dynamic>.from(v))
              .toList()
        : <Map<String, dynamic>>[];
    final rawStatus = (data['privateStatus'] ?? 'notSubmitted').toString();
    final status =
        const {
          'notSubmitted': 'Non envoyé',
          'draft': 'Brouillon',
          'pendingApproval': 'En attente d’examen',
          'approved': 'Approuvé',
          'rejected': 'Refusé ou vérification retirée',
        }[rawStatus] ??
        rawStatus;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          (data['businessName'] ?? 'Établissement').toString(),
          style: const TextStyle(
            color: gold,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: green,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Dossier professionnel', status),
                _line(
                  'Publication de la fiche d’origine',
                  data['publicationStatus'],
                ),
                _line(
                  'Badge sur la fiche d’origine',
                  data['originalVerified'] == true ? 'Oui' : 'Non',
                ),
                _line(
                  'Badge sur une fiche publique',
                  data['publicVerified'] == true ? 'Oui' : 'Non',
                ),
                _line('Copies publiques liées', data['publicCopies']),
                if (data['publicProfiles'] is List)
                  for (final copy
                      in (data['publicProfiles'] as List).whereType<Map>())
                    _line('Fiche liée', '${copy['title']} · ${copy['path']}'),
                _line(
                  'Référence',
                  '${data['sourceCollection']}/${data['businessId']}',
                ),
                const Text(
                  'Un badge public seul ne remplace pas l’examen du dossier professionnel.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: green,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Nom légal', info['legalName']),
                _line('Immatriculation', info['registrationNumber']),
                _line('Pays', info['country']),
                _line('Adresse professionnelle', info['address']),
                _line('Téléphone du dossier', info['phone']),
                _line(
                  'Téléphone lié au compte',
                  data['phoneLinked'] == true ? 'Oui' : 'Non',
                ),
                _line(
                  'E-mail vérifié',
                  data['emailVerified'] == true ? 'Oui' : 'Non',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Documents à examiner',
          style: TextStyle(
            color: gold,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final attachment in attachments)
          Card(
            color: green,
            child: ListTile(
              leading: const Icon(Icons.description_outlined, color: gold),
              title: Text(
                attachment['label'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: attachment['available'] == true
                  ? null
                  : const Text(
                      'Lien non reconnu : nouveau dépôt nécessaire',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
              trailing: attachment['available'] == true
                  ? IconButton(
                      tooltip: 'Consulter le document',
                      onPressed: _busy ? null : () => _document(attachment),
                      icon: const Icon(Icons.open_in_new, color: gold),
                    )
                  : null,
            ),
          ),
        if (attachments.isEmpty)
          const Text(
            'Aucun document déposé.',
            style: TextStyle(color: Colors.white70),
          ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Éléments à compléter avant approbation',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in missing) _line('À vérifier', item),
        ],
        if ((data['rejectionReason'] ?? '').toString().isNotEmpty)
          _line('Motif enregistré', data['rejectionReason']),
        if (data['stripeSupported'] != true)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Cette fiche publique ne possède pas de lien vers une soumission professionnelle. '
              'Stripe utilise la fiche d’origine ; ce lien doit être vérifié séparément.',
              style: TextStyle(color: Colors.orangeAccent, height: 1.4),
            ),
          ),
        const SizedBox(height: 18),
        if (data['canApprove'] == true)
          _button(
            'Approuver le dossier professionnel',
            Icons.verified_user_outlined,
            () => _review('approve'),
          ),
        if (data['canSynchronize'] == true)
          _button(
            'Synchroniser l’approbation',
            Icons.sync,
            () => _review('synchronize'),
          ),
        if (data['canReject'] == true)
          _button(
            'Refuser et demander une correction',
            Icons.edit_note,
            () => _review('reject'),
            outlined: true,
          ),
        if (data['canRevoke'] == true)
          _button(
            'Retirer la vérification',
            Icons.remove_circle_outline,
            () => _review('revoke'),
            outlined: true,
          ),
        const SizedBox(height: 12),
        const Text(
          'La vérification reste indépendante des abonnements Silver, Gold et VIP. '
          'Stripe reste en mode TEST. Aucun paiement réel ne sera activé.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: CircularProgressIndicator(color: gold)),
          ),
      ],
    );
  }

  Widget _button(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    final child = Text(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: outlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: gold,
                side: const BorderSide(color: gold),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy ? null : onPressed,
              icon: Icon(icon),
              label: child,
            )
          : FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: dark,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy ? null : onPressed,
              icon: Icon(icon),
              label: child,
            ),
    );
  }
}
