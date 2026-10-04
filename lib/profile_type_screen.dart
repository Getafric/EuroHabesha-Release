import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dynamic_submission_screen.dart';

class ProfileTypeScreen extends StatefulWidget {
  const ProfileTypeScreen({super.key});

  @override
  State<ProfileTypeScreen> createState() => _ProfileTypeScreenState();
}

class _ProfileTypeScreenState extends State<ProfileTypeScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  String? _savingType;

  final List<_ProfileTypeOption> _types = const [
    _ProfileTypeOption(
      id: 'entreprise',
      title: 'Entreprise',
      description: 'Restaurant, boutique, commerce ou société.',
      icon: Icons.storefront_outlined,
    ),
    _ProfileTypeOption(
      id: 'professionnel',
      title: 'Professionnel',
      description: 'Indépendant, prestataire ou professionnel.',
      icon: Icons.business_center_outlined,
    ),
    _ProfileTypeOption(
      id: 'employeur',
      title: 'Employeur',
      description: 'Entreprise ou personne proposant des emplois.',
      icon: Icons.work_outline,
    ),
    _ProfileTypeOption(
      id: 'evenement',
      title: 'Événement',
      description: 'Créer et gérer vos événements.',
      icon: Icons.event_outlined,
    ),
  ];

  Future<void> _selectType(_ProfileTypeOption type) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour créer un profil.'),
        ),
      );
      return;
    }

    setState(() => _savingType = type.id);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'accountType': type.id,
        'profileCreated': false,
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.title} sélectionné.'),
        ),
      );

      if (type.id == 'entreprise') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DynamicSubmissionScreen(
              type: SubmissionType.business,
            ),
          ),
        );
        return;
      }

      if (type.id == 'professionnel') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DynamicSubmissionScreen(
              type: SubmissionType.professional,
            ),
          ),
        );
        return;
      }
      if (type.id == 'evenement') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DynamicSubmissionScreen(
              type: SubmissionType.event,
            ),
          ),
        );
        return;
      }
      if (type.id == 'employeur') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DynamicSubmissionScreen(
              type: SubmissionType.employer,
            ),
          ),
        );
        return;
      }

      Navigator.pop(context, type.id);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’enregistrer le type de profil : $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingType = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Créer mon profil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Quel type de profil ?',
              style: TextStyle(
                color: primaryGold,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez le profil qui correspond à votre activité. '
              'Vous pourrez ensuite compléter vos informations.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ..._types.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _savingType == null ? () => _selectType(type) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: primaryDarkGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              type.icon,
                              color: primaryGold,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.description,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_savingType == type.id)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryGold,
                              ),
                            )
                          else
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white38,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTypeOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _ProfileTypeOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
