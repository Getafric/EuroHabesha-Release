/// Presentation only. Purchases and membership grants remain disabled.
class ProfessionalMembershipPlan {
  const ProfessionalMembershipPlan({
    required this.id,
    required this.title,
    required this.monthlyPromotions,
    required this.description,
    required this.rotation,
  });

  final String id;
  final String title;
  final int monthlyPromotions;
  final String description;
  final String rotation;
}

class ProfessionalMembershipSettings {
  const ProfessionalMembershipSettings({
    this.displayEnabled = false,
    this.silverMonthlyPromotions = 1,
    this.goldMonthlyPromotions = 2,
    this.vipMonthlyPromotions = 4,
    this.revision = 0,
    this.compatible = true,
  });

  final bool displayEnabled;
  final int silverMonthlyPromotions;
  final int goldMonthlyPromotions;
  final int vipMonthlyPromotions;
  final int revision;
  final bool compatible;

  // Deliberately not controlled by an editable Firestore boolean.
  bool get salesEnabled => false;

  factory ProfessionalMembershipSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const ProfessionalMembershipSettings();
    }
    final silver = data['silverMonthlyPromotions'];
    final gold = data['goldMonthlyPromotions'];
    final vip = data['vipMonthlyPromotions'];
    final revision = data['revision'];
    final valid =
        data['schemaVersion'] == 1 &&
        data['displayEnabled'] is bool &&
        data['salesEnabled'] == false &&
        silver is int &&
        silver >= 0 &&
        silver <= 20 &&
        gold is int &&
        gold >= silver &&
        gold <= 20 &&
        vip is int &&
        vip >= gold &&
        vip <= 20 &&
        revision is int &&
        revision >= 1;
    if (!valid) {
      return const ProfessionalMembershipSettings(compatible: false);
    }
    return ProfessionalMembershipSettings(
      displayEnabled: data['displayEnabled'] == true,
      silverMonthlyPromotions: silver,
      goldMonthlyPromotions: gold,
      vipMonthlyPromotions: vip,
      revision: revision,
    );
  }

  List<ProfessionalMembershipPlan> get plans => [
    ProfessionalMembershipPlan(
      id: 'silver',
      title: 'SILVER',
      monthlyPromotions: silverMonthlyPromotions,
      description: 'Pour démarrer',
      rotation: 'Rotation standard',
    ),
    ProfessionalMembershipPlan(
      id: 'gold',
      title: 'GOLD',
      monthlyPromotions: goldMonthlyPromotions,
      description: 'Pour se développer',
      rotation: 'Rotation renforcée',
    ),
    ProfessionalMembershipPlan(
      id: 'vip',
      title: 'VIP',
      monthlyPromotions: vipMonthlyPromotions,
      description: 'Pour rayonner',
      rotation: 'Rotation prioritaire',
    ),
  ];

  Map<String, dynamic> draft({required String uid, required Object timestamp}) {
    return {
      'schemaVersion': 1,
      'displayEnabled': displayEnabled,
      'salesEnabled': false,
      'silverMonthlyPromotions': silverMonthlyPromotions,
      'goldMonthlyPromotions': goldMonthlyPromotions,
      'vipMonthlyPromotions': vipMonthlyPromotions,
      'revision': revision + 1,
      'updatedAt': timestamp,
      'updatedByUid': uid,
    };
  }
}
