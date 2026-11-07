import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'business_orders_screen.dart';
import 'professional_payments_screen.dart';
import 'professional_sales_summary.dart';

/// Compact presentation of the existing saved-order reporting.
class ProfessionalSalesScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  final String businessName;
  const ProfessionalSalesScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.businessName,
  });

  @override
  State<ProfessionalSalesScreen> createState() =>
      _ProfessionalSalesScreenState();
}

class _ProfessionalSalesScreenState extends State<ProfessionalSalesScreen> {
  static const _dark = Color(0xFF061E12);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF004D40);
  static const _white = Colors.white;
  int _period = 2;

  String _owner(Map<String, dynamic> data) {
    for (final key in ['ownerId', 'submittedBy', 'creatorId']) {
      final value = orderText(data[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Widget _notice(String text, {IconData icon = Icons.info_outline}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _gold, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _gold.withValues(alpha: 0.25)),
    ),
    child: child,
  );

  Widget _row(String label, String value, {IconData? icon}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 21, color: _gold),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(color: _white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _gold,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _metric(String label, String value, IconData icon) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _gold, size: 25),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: _white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _disclosure(String title, List<Widget> children, String key) =>
      Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.2)),
        ),
        child: ExpansionTile(
          key: PageStorageKey(
            '${FirebaseAuth.instance.currentUser?.uid}:'
            '${widget.sourceCollection}:${widget.businessId}:$key',
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: const Icon(Icons.info_outline, color: _gold, size: 21),
          iconColor: _gold,
          collapsedIconColor: _gold,
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: children,
        ),
      );

  Widget _accountOrders() => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: _gold,
      side: const BorderSide(color: _gold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    icon: const Icon(Icons.receipt_long_outlined),
    label: const AppText(
      'Commandes de tout mon compte',
      textAlign: TextAlign.center,
    ),
    onPressed: () => Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BusinessOrdersScreen(businessId: widget.businessId),
      ),
    ),
  );

  Widget _explanations(String key) => _disclosure('Comprendre les chiffres', [
    _notice(
      'Les ventes utilisent la date de paiement enregistrée. Les commandes '
      'reçues utilisent leur date de création. Dates selon l’heure du téléphone.',
    ),
    _notice(
      'Une commande terminée n’est pas automatiquement payée. Les espèces '
      'déclarées ne prouvent pas un versement bancaire.',
    ),
    _notice(
      'Ce suivi porte sur les commandes de cet établissement. Les billets '
      'd’événements et les abonnements ne sont pas inclus.',
    ),
  ], key);

  Widget _overview(ProfessionalSalesSummary summary) {
    final metrics = [
      _metric(
        'Ventes déclarées',
        summary.missingAmounts == 0
            ? savedOrderMoney(summary.grossCents)
            : 'Montant incomplet',
        Icons.payments_outlined,
      ),
      _metric('Déclarées payées', '${summary.paid}', Icons.task_alt),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns =
                constraints.maxWidth >= 300 &&
                MediaQuery.textScalerOf(context).scale(14) <= 20;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: twoColumns
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth,
                    child: metric,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _panel(
          Column(
            children: [
              _row(
                'Commandes reçues',
                '${summary.received}',
                icon: Icons.shopping_bag_outlined,
              ),
              const Divider(height: 1, color: Colors.white12),
              _row(
                'Total clients',
                summary.missingTotals == 0
                    ? savedOrderMoney(summary.customerTotalsCents)
                    : 'Montant incomplet',
                icon: Icons.receipt_outlined,
              ),
              const Divider(height: 1, color: Colors.white12),
              _row(
                'En espèces / livraison',
                '${summary.cashPaid}',
                icon: Icons.payments_outlined,
              ),
              const Divider(height: 1, color: Colors.white12),
              _row(
                'En ligne',
                '${summary.onlinePaid}',
                icon: Icons.credit_card_outlined,
              ),
              if (summary.otherPaid > 0) ...[
                const Divider(height: 1, color: Colors.white12),
                _row('Autres paiements', '${summary.otherPaid}'),
              ],
            ],
          ),
        ),
        if (summary.received == 0 && summary.paid == 0) ...[
          const SizedBox(height: 12),
          _notice(
            'Aucune commande sur cette période.',
            icon: Icons.receipt_long_outlined,
          ),
        ],
        if (summary.received > 0 && summary.paid == 0)
          _notice('Aucun paiement daté pour cette période.'),
        if (summary.missingAmounts +
                summary.missingTotals +
                summary.missingCommissions +
                summary.missingStripeFees +
                summary.missingPaidDates +
                summary.inconsistentOrders +
                summary.invalidCurrency >
            0)
          _notice('Des données sont à vérifier dans l’onglet Frais.'),
        _explanations('overviewExplanations'),
      ],
    );
  }

  Widget _fees(ProfessionalSalesSummary summary) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    children: [
      _panel(
        Column(
          children: [
            _row(
              'Commission commerçant enregistrée',
              summary.missingCommissions == 0
                  ? savedOrderMoney(summary.registeredCommissionCents)
                  : 'Non renseigné',
            ),
            const Divider(height: 1, color: Colors.white12),
            _row(
              'Marquée prélevée',
              savedOrderMoney(summary.collectedCommissionCents),
            ),
            const Divider(height: 1, color: Colors.white12),
            _row(
              'Sans confirmation de prélèvement',
              savedOrderMoney(summary.uncollectedCommissionCents),
            ),
            const Divider(height: 1, color: Colors.white12),
            _row(
              'Frais Stripe enregistrés',
              summary.onlinePaid == 0
                  ? 'Sans paiement en ligne'
                  : summary.missingStripeFees == 0
                  ? savedOrderMoney(summary.stripeFeesCents)
                  : 'Non renseigné',
            ),
          ],
        ),
      ),
      _notice(
        'Montants enregistrés sur ces commandes, sans recalcul. '
        'Un montant inconnu reste « Non renseigné ».',
      ),
      _disclosure('Détail et points à vérifier', [
        _notice(
          'Cet écran n’active aucun paiement réel et ne modifie '
          'aucun taux de commission. La connexion Stripe garde son mode actuel.',
        ),
        _notice(
          'Aucune estimation des frais Stripe ni de versement bancaire. '
          'Une commission enregistrée sur une commande en espèces n’est pas '
          'forcément encaissée par Euro Habesha.',
        ),
        if (summary.missingPaidDates > 0)
          _notice(
            '${summary.missingPaidDates} commande(s) payée(s) sans date '
            'de paiement : exclues du résumé.',
          ),
        if (summary.missingAmounts +
                summary.missingTotals +
                summary.missingCommissions +
                summary.missingStripeFees >
            0)
          _notice(
            'Certaines données financières manquent. Les montants '
            'incomplets ne sont pas des totaux définitifs.',
          ),
        if (summary.excludedPaidOrders +
                summary.invalidCurrency +
                summary.inconsistentOrders >
            0)
          _notice(
            'Exclusions : ${summary.excludedPaidOrders} commande(s) '
            'annulée(s), remboursée(s) ou avec acompte ; '
            '${summary.invalidCurrency} en devise différente ; '
            '${summary.inconsistentOrders} avec des montants incohérents.',
          ),
        if (summary.testOrders > 0)
          _notice('${summary.testOrders} commande(s) de test exclue(s).'),
        if (summary.unmatched > 0) ...[
          _notice(
            '${summary.unmatched} commande(s) du compte sans lien '
            'certain avec un établissement. Elles ne sont pas attribuées ici.',
          ),
          _accountOrders(),
        ],
      ], 'feeDetails'),
      _explanations('feesExplanations'),
    ],
  );

  Widget _payments() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _dark,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const AppText(
            'Paiements et versements',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProfessionalPaymentsScreen(
                businessId: widget.businessId,
                sourceCollection: widget.sourceCollection,
                businessName: widget.businessName,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _layout(
    String uid,
    Widget overview,
    Widget fees, {
    bool cached = false,
  }) => DefaultTabController(
    length: 3,
    key: ValueKey('tabs:$uid:${widget.sourceCollection}:${widget.businessId}'),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.businessName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const AppText(
                'Période du résumé',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in const {
                    0: 'Aujourd’hui',
                    1: '7 jours',
                    2: 'Ce mois',
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _period == entry.key,
                      selectedColor: _gold,
                      backgroundColor: _green,
                      checkmarkColor: _dark,
                      labelStyle: TextStyle(
                        color: _period == entry.key ? _dark : _white,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _period = entry.key),
                    ),
                ],
              ),
            ],
          ),
        ),
        const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: _gold,
          labelColor: _gold,
          unselectedLabelColor: Colors.white70,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: 12),
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Vue d’ensemble'),
            Tab(text: 'Commandes'),
            Tab(text: 'Frais'),
          ],
        ),
        if (cached)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _notice(
              'Données en cache : les derniers changements peuvent manquer.',
              icon: Icons.cloud_off_outlined,
            ),
          ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              overview,
              BusinessOrdersScreen(
                businessId: widget.businessId,
                sourceCollection: widget.sourceCollection,
                embedded: true,
              ),
              fees,
            ],
          ),
        ),
        _payments(),
      ],
    ),
  );

  Widget _report(
    String uid,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    key: ValueKey('sales:$uid:${widget.sourceCollection}:${widget.businessId}'),
    stream: FirebaseFirestore.instance
        .collection('cashOnDeliveryOrders')
        .where('sellerId', isEqualTo: uid)
        .limit(1001)
        .snapshots(includeMetadataChanges: true),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _notice(
              'Impossible de lire les ventes. Vérifiez votre connexion '
              'et vos autorisations, puis réessayez.',
            ),
          ],
        );
        return _layout(uid, error, error);
      }
      if (!snapshot.hasData) {
        const loading = Center(child: CircularProgressIndicator(color: _gold));
        return _layout(uid, loading, loading);
      }
      final docs = snapshot.data!.docs;
      if (docs.length >= 1001) {
        final limit = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _notice(
              'Votre compte contient plus de 1 000 commandes. Le résumé '
              'est suspendu pour éviter des totaux incomplets. Un rapport '
              'calculé sur le serveur sera nécessaire pour cet historique.',
            ),
          ],
        );
        return _layout(
          uid,
          limit,
          limit,
          cached: snapshot.data!.metadata.isFromCache,
        );
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = switch (_period) {
        0 => today,
        1 => DateTime(now.year, now.month, now.day - 6),
        _ => DateTime(now.year, now.month),
      };
      final end = DateTime(now.year, now.month, now.day + 1);
      final summary = ProfessionalSalesSummary.fromOrders(
        docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          for (final key in ['createdAt', 'paidAt']) {
            if (data[key] is Timestamp) {
              data[key] = (data[key] as Timestamp).toDate();
            }
          }
          return data;
        }),
        sourceCollection: widget.sourceCollection,
        businessId: widget.businessId,
        ownerId: uid,
        start: start,
        end: end,
      );
      return _layout(
        uid,
        _overview(summary),
        _fees(summary),
        cached: snapshot.data!.metadata.isFromCache,
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      backgroundColor: _dark,
      foregroundColor: _gold,
      title: const AppText('Mes ventes'),
      actions: [
        IconButton(
          tooltip: 'Actualiser la période',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() {}),
        ),
      ],
    ),
    body: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, auth) {
        final user = auth.data;
        if (user == null || user.isAnonymous) {
          return Center(
            child: _notice('Connectez-vous à votre compte professionnel.'),
          );
        }
        if (!professionalOrderCollections.contains(widget.sourceCollection) ||
            widget.businessId.isEmpty ||
            widget.businessId.contains('/')) {
          return Center(child: _notice('Établissement non pris en charge.'));
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey(
            'owner:${user.uid}:${widget.sourceCollection}:${widget.businessId}',
          ),
          stream: FirebaseFirestore.instance
              .collection(widget.sourceCollection)
              .doc(widget.businessId)
              .snapshots(),
          builder: (context, profile) {
            if (profile.hasError) {
              return Center(
                child: _notice(
                  'Impossible de vérifier votre accès '
                  'à cet établissement.',
                ),
              );
            }
            if (!profile.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }
            if (!profile.data!.exists ||
                _owner(profile.data!.data() ?? {}) != user.uid) {
              return Center(
                child: _notice('Cet établissement ne vous appartient pas.'),
              );
            }
            return _report(user.uid);
          },
        );
      },
    ),
  );
}
