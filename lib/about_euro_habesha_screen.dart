import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutEuroHabeshaScreen extends StatelessWidget {
  const AboutEuroHabeshaScreen({super.key});
  static const darkGreen = Color(0xFF061E12);
  static const cardGreen = Color(0xFF004D40);
  static const gold = Color(0xFFFFD700);
  static const white = Color(0xFFF7F7F2);
  static const contactEmail = 'contact@eurohabesha.eu';
  static const supportEmail = 'support@eurohabesha.eu';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: darkGreen,
    appBar: AppBar(backgroundColor: darkGreen, foregroundColor: white,
      centerTitle: true, title: const Text('À propos de Euro Habesha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 12),
      Center(child: Container(width: 104, height: 104,
        decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(24), border: Border.all(color: gold, width: 1.5)),
        padding: const EdgeInsets.all(8),
        child: Image.asset('assets/images/euro_habesha_logo.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.hub, color: gold, size: 58)))),
      const SizedBox(height: 16),
      const Text('Euro Habesha', textAlign: TextAlign.center, style: TextStyle(color: gold, fontSize: 30, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Ethiopian & Eritrean Diaspora', textAlign: TextAlign.center, style: TextStyle(color: white, fontSize: 15)),
      const SizedBox(height: 6),
      const Text('Connecter • Partager • Réussir', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 30),
      _section(Icons.language, 'Notre mission', 'Euro Habesha est une plateforme dédiée à la diaspora éthiopienne et érythréenne partout dans le monde.\n\nNotre mission est de connecter les personnes, les communautés, les professionnels et les entreprises, de promouvoir notre culture et de créer de nouvelles opportunités, où que vous soyez.'),
      _section(Icons.groups, 'Une communauté sans frontières', 'Euro Habesha permet à la diaspora éthiopienne et érythréenne, partout dans le monde, de rester connectée, de partager des informations et de s’entraider.'),
      const SizedBox(height: 12),
      const Text('Découvrez nos services', style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      _service(Icons.work_outline, 'Emplois', 'Découvrez et partagez des opportunités professionnelles.'),
      _service(Icons.storefront_outlined, 'Commerces', 'Découvrez les restaurants, commerces et entreprises.'),
      _service(Icons.shopping_bag_outlined, 'Marché', 'Publiez et consultez des annonces de produits.'),
      _service(Icons.business_center_outlined, 'Professionnels', 'Trouvez des prestataires et des services professionnels.'),
      _service(Icons.event_outlined, 'Événements', 'Découvrez les concerts, festivals et rencontres.'),
      _service(Icons.diversity_3_outlined, 'Habesha Connect', 'Échangez, partagez et renforcez les liens communautaires.'),
      const SizedBox(height: 16),
      _section(Icons.verified_user_outlined, 'Notre engagement', 'Respect, sécurité, confidentialité et soutien à la communauté. Nous souhaitons construire un espace utile, accueillant et digne de confiance.'),
      const SizedBox(height: 12),
      const Text('Contactez-nous', style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _emailCard(context, Icons.mail_outline, 'Contact général et partenariats', contactEmail),
      const SizedBox(height: 10),
      _emailCard(context, Icons.support_agent, 'Assistance et problèmes techniques', supportEmail),
      const SizedBox(height: 24),
      const Text('Euro Habesha • Une diaspora, des connexions sans frontières', textAlign: TextAlign.center, style: TextStyle(color: gold, fontSize: 12)),
      const SizedBox(height: 20),
    ])),
  );

  Widget _section(IconData icon, String title, String description) => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(18), border: Border.all(color: gold.withValues(alpha: 0.35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: gold), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 12), Text(description, style: const TextStyle(color: white, fontSize: 14, height: 1.6)),
    ]),
  );

  Widget _service(IconData icon, String title, String description) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [Icon(icon, color: gold, size: 28), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(description, style: const TextStyle(color: white, fontSize: 13)),
    ]))]),
  );

  Widget _emailCard(BuildContext context, IconData icon, String title, String email) => InkWell(
    onTap: () async {
      await Clipboard.setData(ClipboardData(text: email));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Adresse copiée : $email')));
    },
    borderRadius: BorderRadius.circular(14),
    child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(14), border: Border.all(color: gold.withValues(alpha: 0.5))),
      child: Row(children: [Icon(icon, color: gold, size: 27), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: white, fontSize: 13)), const SizedBox(height: 5), Text(email, style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 14)),
      ])), const Icon(Icons.copy, color: gold, size: 18)])),
  );
}
