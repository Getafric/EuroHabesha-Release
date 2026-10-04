import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'habesha_connect_feed_screen.dart';

class HabeshaConnectScreen extends StatefulWidget {
  const HabeshaConnectScreen({super.key});

  @override
  State<HabeshaConnectScreen> createState() => _HabeshaConnectScreenState();
}

class _HabeshaConnectScreenState extends State<HabeshaConnectScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  static const Color softText = Color(0xFFD5DFDA);
  static const Color mutedText = Color(0xFFAAB9B2);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<_ConnectCategory> _categories = const [
    _ConnectCategory(
      title: 'Groupes & Associations',
      icon: Icons.groups_rounded,
      description:
          'Associations, groupes locaux, églises, mosquées et organisations communautaires.',
    ),
    _ConnectCategory(
      title: 'Habesha par ville',
      icon: Icons.location_city_rounded,
      description: 'Trouvez et échangez avec des Habesha dans votre ville.',
    ),
    _ConnectCategory(
      title: 'Entraide',
      icon: Icons.handshake_rounded,
      description: 'Questions, aide quotidienne, conseils et solidarité.',
    ),
    _ConnectCategory(
      title: 'Logement',
      icon: Icons.home_rounded,
      description: 'Chambres, logements, colocations et conseils immobiliers.',
    ),
    _ConnectCategory(
      title: 'Transport & déplacement',
      icon: Icons.directions_car_rounded,
      description: 'Transport, covoiturage, trajets et déplacements.',
    ),
    _ConnectCategory(
      title: 'Aide administrative',
      icon: Icons.description_rounded,
      description:
          'Démarches, documents, administrations et informations pratiques.',
    ),
    _ConnectCategory(
      title: 'Langues & traduction',
      icon: Icons.translate_rounded,
      description: 'Amharique, tigrinya, français, anglais et autres langues.',
    ),
    _ConnectCategory(
      title: 'Études & formation',
      icon: Icons.school_rounded,
      description: 'Études, formations, écoles, universités et apprentissage.',
    ),
    _ConnectCategory(
      title: 'Familles & parents',
      icon: Icons.family_restroom_rounded,
      description: 'Parents, enfants, familles et conseils du quotidien.',
    ),
    _ConnectCategory(
      title: 'Carrière & mentorat',
      icon: Icons.work_outline_rounded,
      description: 'Carrière, conseils professionnels, mentorat et réseau.',
    ),
    _ConnectCategory(
      title: 'Culture & rencontres',
      icon: Icons.celebration_rounded,
      description:
          'Culture, rencontres, traditions et activités communautaires.',
    ),
    _ConnectCategory(
      title: 'Bénévolat & solidarité',
      icon: Icons.volunteer_activism_rounded,
      description: 'Bénévolat, aide humanitaire et initiatives solidaires.',
    ),
  ];

  List<_ConnectCategory> get _filteredCategories {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _categories;
    }

    return _categories.where((category) {
      return category.title.toLowerCase().contains(query) ||
          category.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  bool get _hasRealAccount {
    final user = _currentUser;
    return user != null && !user.isAnonymous;
  }

  Future<bool> _requireAccount() async {
    if (_hasRealAccount) {
      return true;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                color: primaryGold,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Compte requis',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Pour demander de l’aide ou participer à Habesha Connect, vous devez avoir un compte Euro Habesha.',
            style: TextStyle(
              color: softText,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Fermer',
                style: TextStyle(color: primaryGold),
              ),
            ),
          ],
        );
      },
    );

    return false;
  }

  void _openFeed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HabeshaConnectFeedScreen(),
      ),
    );
  }

  void _openCategory(_ConnectCategory category) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        category.icon,
                        color: primaryGold,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        category.title,
                        style: const TextStyle(
                          color: primaryGold,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  category.description,
                  style: const TextStyle(
                    color: softText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: primaryDarkGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openFeed();
                    },
                    icon: const Icon(Icons.dynamic_feed_rounded),
                    label: const Text(
                      'Voir les publications',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: primaryGold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openRequestForm(
                        initialCategory: category.title,
                      );
                    },
                    icon: const Icon(
                      Icons.campaign_rounded,
                      color: primaryGold,
                    ),
                    label: const Text(
                      'Demander à la communauté',
                      style: TextStyle(
                        color: primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRequestForm({
    String? initialCategory,
  }) async {
    final hasAccount = await _requireAccount();

    if (!hasAccount || !mounted) {
      return;
    }

    final questionController = TextEditingController();
    final cityController = TextEditingController();
    final countryController = TextEditingController();

    String selectedCategory = initialCategory ?? _categories.first.title;

    bool sending = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalContext).size.height * 0.90,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            color: primaryGold,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Demander à la communauté',
                              style: TextStyle(
                                color: primaryGold,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Votre demande sera vérifiée par un administrateur avant d’être publiée.',
                        style: TextStyle(
                          color: softText,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _formLabel('Catégorie'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: primaryDarkGreen,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: cardGreen,
                            style: const TextStyle(color: Colors.white),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.title,
                                child: Text(category.title),
                              );
                            }).toList(),
                            onChanged: sending
                                ? null
                                : (value) {
                                    if (value == null) return;

                                    setModalState(() {
                                      selectedCategory = value;
                                    });
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _formLabel('Que recherchez-vous ? *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: questionController,
                        maxLines: 5,
                        enabled: !sending,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Exemple : Je cherche un interprète amharique/français à Lyon.',
                        ),
                      ),
                      const SizedBox(height: 15),
                      _formLabel('Ville'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: cityController,
                        enabled: !sending,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Exemple : Lyon'),
                      ),
                      const SizedBox(height: 15),
                      _formLabel('Pays'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: countryController,
                        enabled: !sending,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Exemple : France'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryDarkGreen,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: sending
                              ? null
                              : () async {
                                  final question =
                                      questionController.text.trim();

                                  if (question.isEmpty) {
                                    if (!modalContext.mounted) return;

                                    ScaffoldMessenger.of(modalContext)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Écrivez votre demande.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final user =
                                      FirebaseAuth.instance.currentUser;

                                  if (user == null || user.isAnonymous) {
                                    if (modalContext.mounted) {
                                      Navigator.of(modalContext).pop();
                                    }
                                    if (mounted) {
                                      await _requireAccount();
                                    }
                                    return;
                                  }

                                  setModalState(() {
                                    sending = true;
                                  });

                                  try {
                                    await FirebaseFirestore.instance
                                        .collection(
                                      'habeshaConnectRequests',
                                    )
                                        .add({
                                      'category': selectedCategory,
                                      'question': question,
                                      'text': question,
                                      'city': cityController.text.trim(),
                                      'country': countryController.text.trim(),
                                      'authorId': user.uid,
                                      'authorName':
                                          user.displayName?.trim().isNotEmpty ==
                                                  true
                                              ? user.displayName!.trim()
                                              : 'Membre Euro Habesha',
                                      'authorEmail': user.email ?? '',
                                      'status': 'pending',
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    if (!mounted) return;

                                    if (modalContext.mounted) {
                                      Navigator.of(modalContext).pop();
                                    }

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Votre demande a été envoyée. Elle sera visible après validation.',
                                        ),
                                        backgroundColor: cardGreen,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                  } catch (error) {
                                    if (modalContext.mounted) {
                                      setModalState(() {
                                        sending = false;
                                      });

                                      ScaffoldMessenger.of(modalContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Impossible d’envoyer la demande : $error',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryDarkGreen,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            sending ? 'Envoi...' : 'Envoyer la demande',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    questionController.dispose();
    cityController.dispose();
    countryController.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryGold),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_rounded,
              color: primaryGold,
              size: 25,
            ),
            SizedBox(width: 8),
            Text(
              'Habesha Connect',
              style: TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Feed',
            onPressed: _openFeed,
            icon: const Icon(Icons.dynamic_feed_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _buildSearch(),
            const SizedBox(height: 12),
            _buildAskCommunityButton(),
            const SizedBox(height: 18),
            _buildFeedCard(),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Explorer la communauté',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${filtered.length}',
                  style: const TextStyle(color: mutedText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _buildNoCategoryResult()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.94,
                ),
                itemBuilder: (context, index) {
                  return _buildCategoryCard(filtered[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            cardGreen,
            primaryDarkGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: primaryGold,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: primaryDarkGreen,
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Habesha Connect',
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'La communauté Habesha, partout dans le monde.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trouvez, demandez, partagez et entraidez-vous.',
            style: TextStyle(
              color: softText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Je cherche quelque chose...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: primaryGold,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(
                  Icons.clear_rounded,
                  color: Colors.white54,
                ),
              )
            : null,
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryGold,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildAskCommunityButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: primaryDarkGreen,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _openRequestForm(),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text(
          'Demander à la communauté',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard() {
    return InkWell(
      onTap: _openFeed,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: primaryGold.withValues(alpha: 0.18),
          ),
        ),
        child: const Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x1FFFD700),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.dynamic_feed_rounded,
                  color: primaryGold,
                  size: 26,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feed de la communauté',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Découvrez les demandes et publications approuvées.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: primaryGold,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_ConnectCategory category) {
    return InkWell(
      onTap: () => _openCategory(category),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryGold.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                category.icon,
                color: primaryGold,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              category.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: mutedText,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCategoryResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: primaryGold,
            size: 35,
          ),
          const SizedBox(height: 10),
          const Text(
            'Aucune catégorie trouvée.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Vous pouvez demander directement à la communauté.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openRequestForm(),
            icon: const Icon(
              Icons.campaign_rounded,
              color: primaryGold,
            ),
            label: const Text(
              'Demander à la communauté',
              style: TextStyle(color: primaryGold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: primaryGold,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
      ),
      filled: true,
      fillColor: primaryDarkGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: primaryGold.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ConnectCategory {
  final String title;
  final IconData icon;
  final String description;

  const _ConnectCategory({
    required this.title,
    required this.icon,
    required this.description,
  });
}
