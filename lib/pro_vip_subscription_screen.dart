import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'professional_membership.dart';
import 'professional_subscription_price_widgets.dart';
import 'professional_membership_badge.dart';
import 'store_subscription_service.dart';

/// Catalogue uniquement : aucun achat ni droit n'est accordé ici.
class ProVipSubscriptionScreen extends StatefulWidget {
  const ProVipSubscriptionScreen({
    super.key,
    this.sourceCollection,
    this.businessId,
    this.businessName,
    this.adminPreview = false,
  });

  final String? sourceCollection;
  final String? businessId;
  final String? businessName;
  final bool adminPreview;

  static const dark = Color(0xFF061E12);
  static const green = Color(0xFF004D40);
  static const gold = Color(0xFFFFD700);

  @override
  State<ProVipSubscriptionScreen> createState() =>
      _ProVipSubscriptionScreenState();
}

class _ProVipSubscriptionScreenState extends State<ProVipSubscriptionScreen> {
  late final Future<StoreSubscriptionCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = StoreSubscriptionService().loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final preview = widget.adminPreview && AppSession.isSuperAdmin;
    return Scaffold(
      backgroundColor: ProVipSubscriptionScreen.dark,
      appBar: AppBar(
        backgroundColor: ProVipSubscriptionScreen.dark,
        foregroundColor: ProVipSubscriptionScreen.gold,
        title: const AppText('Visibilité & abonnements'),
      ),
      body: user == null || user.isAnonymous
          ? const Center(
              child: AppText(
                'Connectez-vous pour consulter les formules.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('app_settings')
                  .doc('professionalSubscriptions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: AppText(
                        'Les formules sont momentanément indisponibles.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ProVipSubscriptionScreen.gold,
                    ),
                  );
                }
                final settings = ProfessionalMembershipSettings.fromMap(
                  snapshot.data!.data(),
                );
                if (!settings.compatible ||
                    (!preview && !settings.displayEnabled)) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: AppText(
                        'Les formules Silver, Gold et VIP ne sont pas encore ouvertes. '
                        'Les services habituels restent disponibles.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return FutureBuilder<StoreSubscriptionCatalog>(
                  future: _catalog,
                  builder: (context, storeSnapshot) {
                    final catalog = storeSnapshot.data;
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          preview
                              ? 'Aperçu administrateur'
                              : 'Préparez votre visibilité',
                          style: const TextStyle(
                            color: ProVipSubscriptionScreen.gold,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if ((widget.businessName ?? '').isNotEmpty)
                          Text(
                            widget.businessName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                        const SizedBox(height: 8),
                        const AppText(
                          'Offres en préparation : aucun achat disponible. '
                          'Les prix affichés par la boutique sont indicatifs '
                          'jusqu’à l’ouverture des souscriptions.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        for (final plan in settings.plans)
                          _plan(plan, catalog, storeSnapshot.connectionState),
                        const Card(
                          color: ProVipSubscriptionScreen.green,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: ProVipSubscriptionScreen.gold,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: AppText(
                                    'La vérification professionnelle reste indépendante. '
                                    'Un abonnement ne valide pas l’identité de l’établissement.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const AppText(
                          'Les avantages affichés sont proposés pour le futur lancement. '
                          'La rotation dépendra de la proximité, de la pertinence '
                          'et des places disponibles. Les promotions resteront '
                          'soumises à validation admin. Aucun classement ni '
                          'nombre de clients n’est garanti.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor:
                                ProVipSubscriptionScreen.green,
                            disabledForegroundColor: Colors.white70,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.lock_outline),
                          label: const AppText(
                            'Souscriptions bientôt disponibles',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const AppText(
                          'Aucun paiement, badge actif ou quota n’est accordé par cet écran.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _plan(
    ProfessionalMembershipPlan plan,
    StoreSubscriptionCatalog? catalog,
    ConnectionState state,
  ) {
    final accent = plan.id == 'silver'
        ? const Color(0xFFDEE4E8)
        : ProVipSubscriptionScreen.gold;
    final product = catalog?.products[plan.id];
    final String storeMessage;
    if (state != ConnectionState.done) {
      storeMessage = 'Consultation de la boutique…';
    } else if (product != null) {
      storeMessage = '${product.price} / 6 mois · prix de la boutique';
    } else if (catalog?.error != null) {
      storeMessage = 'Prix boutique indisponible : ${catalog!.error}';
    } else {
      storeMessage = 'Prix boutique indisponible pour cette formule.';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProVipSubscriptionScreen.green,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: plan.id == 'gold' ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfessionalMembershipBadge(tier: plan.id),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        color: accent,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      plan.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppText(
            '${plan.monthlyPromotions} promotion(s) incluse(s) par mois — proposition',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(plan.rotation, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          Text(
            storeMessage,
            style: const TextStyle(
              color: ProVipSubscriptionScreen.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const AppText(
            'Tarif de préparation défini dans l’administration :',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          ProfessionalSubscriptionPricePreview(tier: plan.id),
        ],
      ),
    );
  }
}

/// Entrée existante du tableau de bord professionnel.
class ProfessionalMembershipAction extends StatelessWidget {
  const ProfessionalMembershipAction({
    super.key,
    required this.sourceCollection,
    required this.businessId,
    required this.businessName,
  });
  final String sourceCollection;
  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('app_settings')
          .doc('professionalSubscriptions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final settings = ProfessionalMembershipSettings.fromMap(
          snapshot.data!.data(),
        );
        if (!settings.compatible || !settings.displayEnabled) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            color: ProVipSubscriptionScreen.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: ProVipSubscriptionScreen.gold,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProVipSubscriptionScreen(
                    sourceCollection: sourceCollection,
                    businessId: businessId,
                    businessName: businessName,
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: ProVipSubscriptionScreen.gold,
                      size: 32,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'Visibilité & abonnements',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          AppText(
                            'Silver · Gold · VIP — bientôt disponible',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: ProVipSubscriptionScreen.gold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
