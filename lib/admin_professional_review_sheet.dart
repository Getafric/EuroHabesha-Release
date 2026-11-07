import 'l10n/app_ui.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_professional_review_data.dart';
import 'public_profile_photo.dart';
import 'service_profession_card.dart';

class AdminProfessionalSubmissionTile extends StatelessWidget {
  final AdminProfessionalReviewData model;
  final VoidCallback onOpen;
  const AdminProfessionalSubmissionTile({
    super.key,
    required this.model,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF004D40),
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: PublicProfilePhoto(
                    urls: model.photos.take(1).toList(),
                    semanticLabel: 'Photo de présentation',
                    fallback: const Icon(
                      Icons.photo_outlined,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        model.categoryLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        model.city,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              model.publicationLabel,
              style: const TextStyle(color: Color(0xFFFFD700)),
            ),
            if (model.photos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: AppText(
                  'Photo de présentation manquante',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700),
              ),
              icon: const Icon(Icons.folder_open_outlined),
              label: const AppText('Examiner le dossier'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminProfessionalReviewSheet extends StatefulWidget {
  final AdminProfessionalReviewData model;
  final String referenceLabel;
  final Future<bool> Function(bool approved) onReview;
  final Future<bool> Function()? onDelete;
  final VoidCallback? onOpenVerification;
  const AdminProfessionalReviewSheet({
    super.key,
    required this.model,
    required this.referenceLabel,
    required this.onReview,
    this.onDelete,
    this.onOpenVerification,
  });
  @override
  State<AdminProfessionalReviewSheet> createState() =>
      _AdminProfessionalReviewSheetState();
}

class _AdminProfessionalReviewSheetState
    extends State<AdminProfessionalReviewSheet> {
  static const gold = Color(0xFFFFD700),
      green = Color(0xFF004D40),
      dark = Color(0xFF061E12);
  bool _busy = false;
  AdminProfessionalReviewData get m => widget.model;
  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> open(Uri? uri) async {
    if (uri == null) {
      message(
        'Cette information n’est pas renseignée ou le lien est invalide.',
      );
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        message('Impossible d’ouvrir ce lien.');
      }
    } catch (_) {
      message('Impossible d’ouvrir ce lien.');
    }
  }

  Future<void> review(bool approved) async {
    if (_busy) return;
    setState(() => _busy = true);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: green,
        title: Text(
          approved ? 'Approuver la publication ?' : 'Refuser la publication ?',
          style: const TextStyle(color: gold),
        ),
        content: const AppText(
          'Cette décision concerne la publication de la fiche. La vérification professionnelle et les paiements sont traités séparément.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText(
              'Annuler',
              style: TextStyle(color: Colors.white),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: dark,
            ),
            child: const AppText('Confirmer'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm != true) {
      setState(() => _busy = false);
      return;
    }
    try {
      final ok = await widget.onReview(approved);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else {
        message('La décision n’a pas été enregistrée. Actualisez le dossier.');
      }
    } catch (_) {
      message('Impossible d’enregistrer cette décision. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> remove() async {
    if (_busy || widget.onDelete == null) return;
    setState(() => _busy = true);
    try {
      final removed = await widget.onDelete!();
      if (removed && mounted) Navigator.pop(context);
    } catch (_) {
      message('Impossible de supprimer cette demande.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: green,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
  Widget row(String label, String value) => value.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
  Widget shortcut(String label, IconData icon, Uri? uri) => OutlinedButton.icon(
    onPressed: uri == null || _busy ? null : () => open(uri),
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: gold,
      disabledForegroundColor: Colors.white38,
    ),
  );
  Widget verification() => card('Vérification professionnelle', [
    Text(
      m.verificationLabel,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 8),
    const AppText(
      'Statut de la fiche d’origine. Les pièces privées sont examinées dans la modération professionnelle.',
      style: TextStyle(color: Colors.white70),
    ),
    const SizedBox(height: 10),
    if (widget.onOpenVerification != null)
      OutlinedButton.icon(
        onPressed: _busy ? null : widget.onOpenVerification,
        style: OutlinedButton.styleFrom(foregroundColor: gold),
        icon: const Icon(Icons.fact_check_outlined),
        label: const AppText('Ouvrir la modération professionnelle'),
      )
    else
      const AppText(
        'L’examen des pièces privées est réservé au Super Admin.',
        style: TextStyle(color: Colors.white70),
      ),
  ]);
  Widget summary() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      card('Présentation', [
        row('Activité', m.categoryLabel),
        row('Description', m.description),
      ]),
      ServiceProfessionCard(data: m.raw),
      if (m.serviceDetails.isEmpty)
        card('Informations de l’activité', [
          row('Zone de prestation', m.area),
          row('Horaires ou disponibilités déclarés', m.hours),
          row('Immatriculation déclarée', m.registration),
        ]),
      card('Coordonnées et emplacement', [
        row('Ville', m.city),
        row('Pays', m.country),
        row('Zone d’intervention', m.area),
        row('Adresse ou zone déclarée', m.address),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            shortcut('Carte', Icons.map_outlined, m.mapUri),
            shortcut('Rechercher', Icons.search, m.searchUri),
            shortcut('Site web', Icons.language, m.websiteUri),
            shortcut('Appeler', Icons.call_outlined, m.phoneUri),
            shortcut('E-mail', Icons.mail_outline, m.emailUri),
          ],
        ),
        const SizedBox(height: 6),
        const AppText(
          'Informations déclarées par le professionnel, à contrôler avant décision.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ]),
      verification(),
    ],
  );
  Widget photos() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (m.photos.isEmpty)
        card('Photo manquante', [
          const AppText(
            'Aucune photo publique n’a été fournie. Le professionnel doit ajouter une photo de présentation avant l’approbation.',
            style: TextStyle(color: Colors.white),
          ),
        ])
      else ...[
        const AppText(
          'Photo de présentation',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: PublicProfilePhoto(
            urls: [m.photos.first],
            semanticLabel: 'Photo de présentation entière',
            fallback: const Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: AppText(
            'Touchez une image pour l’agrandir.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final url in m.photos.skip(1))
              SizedBox(
                width: 140,
                height: 140,
                child: PublicProfilePhoto(
                  urls: [url],
                  semanticLabel: 'Réalisation du professionnel',
                  fallback: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: 14),
      const AppText(
        'Galerie publique de présentation. Les pièces de vérification privées ne sont pas affichées ici.',
        style: TextStyle(color: Colors.white70),
      ),
    ],
  );
  Widget controls() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      card('Contrôles avant publication', [
        row(
          'Photo de présentation',
          m.photos.isEmpty ? 'Manquante' : 'Présente · à examiner',
        ),
        row(
          'Description',
          m.description.isEmpty ? 'Non renseignée' : 'Renseignée · à examiner',
        ),
        row(
          'Coordonnées',
          m.phone.isEmpty && m.email.isEmpty
              ? 'Non renseignées'
              : 'Déclarées · à contrôler',
        ),
        row(
          'Adresse ou zone déclarée',
          m.address.isEmpty ? 'Non renseignée' : m.address,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            shortcut('Ouvrir la carte', Icons.map_outlined, m.mapUri),
            shortcut('Rechercher l’activité', Icons.search, m.searchUri),
          ],
        ),
        const SizedBox(height: 8),
        const AppText(
          'La carte aide au contrôle. Elle ne prouve pas l’existence de l’activité. Un prestataire mobile peut déclarer uniquement sa zone.',
          style: TextStyle(color: Colors.white70),
        ),
      ]),
      card('Informations de contact', [
        row('Téléphone déclaré', m.phone),
        row('E-mail déclaré', m.email),
        row('Envoyé par', m.submittedEmail),
        row('Date d’envoi', m.createdLabel),
        row('Site internet déclaré', m.website),
        row('Pays', m.country),
        row('Immatriculation déclarée', m.registration),
      ]),
      verification(),
      ExpansionTile(
        title: const AppText(
          'Référence du dossier',
          style: TextStyle(color: Colors.white70),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.referenceLabel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      if (widget.onDelete != null)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: OutlinedButton.icon(
            onPressed: _busy ? null : remove,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const AppText('Supprimer définitivement'),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .94,
      child: Material(
        color: dark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close, color: gold),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).height >= 600)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: PublicProfilePhoto(
                          urls: m.photos.take(1).toList(),
                          semanticLabel: 'Photo du professionnel',
                          fallback: const Icon(
                            Icons.photo_outlined,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.categoryLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              m.city,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              m.publicationLabel,
                              style: const TextStyle(color: gold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              const TabBar(
                labelColor: gold,
                unselectedLabelColor: Colors.white70,
                indicatorColor: gold,
                tabs: [
                  Tab(text: 'Résumé'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Contrôles'),
                ],
              ),
              Expanded(
                child: TabBarView(children: [summary(), photos(), controls()]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (m.pending && m.photos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: AppText(
                          'Photo requise avant approbation.',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    if (_busy) const LinearProgressIndicator(color: gold),
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      onPressed: _busy || !m.pending || m.photos.isEmpty
                          ? null
                          : () => review(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: dark,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: AppText('Approuver la publication'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _busy || !m.pending
                          ? null
                          : () => review(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: AppText('Refuser'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
