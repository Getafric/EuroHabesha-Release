import 'professional_sales_screen.dart';
import 'pro_vip_subscription_screen.dart';
import 'advertisement_request_screen.dart';
import 'package:flutter/material.dart';
import 'professional_photo_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'business_orders_screen.dart';
import 'business_screen.dart';
import 'business_table_reservations_screen.dart';
import 'room_layout_editor_screen.dart';
import 'business_menu_management_screen.dart';
import 'notifications_screen.dart';
import 'business_edit_profile_screen.dart';
import 'business_gallery_screen.dart';
import 'business_hours_screen.dart';
import 'jobs_screen.dart';
import 'professional_profile_sync_service.dart';
import 'professional_verification_screen.dart';
import 'professional_payments_screen.dart';
import 'professional_appointments_screen.dart';
import 'table_reservation_option.dart';

class BusinessDashboardScreen extends StatefulWidget {
  // Public constants also used by the header and verification widgets.
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  const BusinessDashboardScreen({super.key});
  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  bool _openingPublicPage = false;

  Future<void> _openPublishedBusiness(
    DocumentSnapshot<Map<String, dynamic>> source,
    String sourceCollection,
  ) async {
    if (_openingPublicPage) {
      return;
    }
    _openingPublicPage = true;
    try {
      final sourceData = source.data() ?? <String, dynamic>{};
      final sourceStatus = sourceData['status']?.toString() ?? '';
      if (!['approved', 'published'].contains(sourceStatus)) {
        throw StateError('Votre établissement n’est pas encore publié.');
      }
      // Follow the original profile link; never select a business by name.
      final matches = await FirebaseFirestore.instance
          .collection('businesses')
          .where('sourceId', isEqualTo: source.id)
          .get();
      final sourceOwner =
          (sourceData['ownerId'] ?? sourceData['submittedBy'] ?? '').toString();
      final candidates = matches.docs.where((doc) {
        final data = doc.data();
        final linkedCollection = (data['sourceCollection'] ?? '').toString();
        final status = (data['status'] ?? 'published').toString();
        final owner = (data['ownerId'] ?? data['submittedBy'] ?? '').toString();
        return linkedCollection == sourceCollection &&
            ['approved', 'published'].contains(status) &&
            (sourceOwner.isEmpty || owner.isEmpty || owner == sourceOwner);
      }).toList();
      if (candidates.isEmpty) {
        throw StateError(
          'Aucune page publique liée à cet établissement. '
          'Le lien de publication doit être vérifié.',
        );
      }
      if (candidates.length != 1) {
        throw StateError(
          'Plusieurs pages publiques sont liées à cet établissement. '
          'Le doublon doit être vérifié avant d’ouvrir la page.',
        );
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BusinessDetailScreen(
            businessData: normalizeBusinessForDetail(candidates.single),
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lecture de la page publique impossible '
            '(${error.code}). Réessayez ou vérifiez les autorisations.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is StateError
          ? error.message.toString()
          : 'Impossible d’ouvrir la page publique : $error';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _openingPublicPage = false;
    }
  }

  String? _selectedBusinessKey;
  Future<List<_OwnedProfessionalProfile>>? _profilesFuture;
  String? _loadedForUid;

  // Diagnostic ciblé : identifie la collection dont la lecture est refusée.
  // Ne modifie aucune donnée Firestore et conserve les trois sources existantes.
  Future<List<_OwnedProfessionalProfile>> _loadProfiles(String uid) async {
    final firestore = FirebaseFirestore.instance;
    const collectionNames = [
      'businessSubmissions',
      'jobSubmissions',
      'employerSubmissions',
    ];
    final profiles = <_OwnedProfessionalProfile>[];

    for (final collectionName in collectionNames) {
      try {
        final snapshot = await firestore
            .collection(collectionName)
            .where('ownerId', isEqualTo: uid)
            .get();
        debugPrint(
          'PRO DASHBOARD OK: $collectionName - ${snapshot.docs.length} profils',
        );
        profiles.addAll(
          snapshot.docs.map(
            (doc) => _OwnedProfessionalProfile(collectionName, doc),
          ),
        );
      } on FirebaseException catch (error) {
        debugPrint(
          'PRO DASHBOARD ERROR: $collectionName - ${error.code} - ${error.message}',
        );
        throw StateError(
          'Lecture refusée pour $collectionName (${error.code}). '
          'Vérifiez les règles Firestore de cette collection.',
        );
      }
    }
    return profiles;
  }

  void _refreshProfiles() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    setState(() => _profilesFuture = _loadProfiles(uid));
  }

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: primaryDarkGreen,
        body: Center(
          child: Text(
            'Vous devez être connecté.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (_loadedForUid != user.uid) {
      _loadedForUid = user.uid;
      _selectedBusinessKey = null;
      _profilesFuture = _loadProfiles(user.uid);
    }
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
        title: const Text(
          'Mon espace professionnel',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser mes établissements',
            icon: const Icon(Icons.refresh, color: primaryGold),
            onPressed: _refreshProfiles,
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('recipientId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData
                  ? snapshot.data!.docs.where((doc) {
                      final data = doc.data();
                      final isUnread = data['read'] != true;
                      final type = data['type']?.toString().trim() ?? '';
                      return isUnread && type != 'message';
                    }).length
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: primaryGold,
                        size: 28,
                      ),
                      onPressed: () {
                        // L'écran des notifications sera connecté ensuite.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<_OwnedProfessionalProfile>>(
        future: _profilesFuture ??= _loadProfiles(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGold),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger votre entreprise.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun profil entreprise trouvé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }
          final profiles = snapshot.data!;
          final selected = profiles.where((p) => p.key == _selectedBusinessKey);
          final profile = selected.isNotEmpty ? selected.first : profiles.first;
          final document = profile.document;
          final data = document.data();
          final sourceCollection = profile.collection;
          final fields = Map<String, dynamic>.from(
            data['fields'] ?? <String, dynamic>{},
          );
          final businessName =
              fields['title']?.toString().trim().isNotEmpty == true
              ? fields['title'].toString()
              : 'Mon espace professionnel';
          final category =
              fields['businessCategory']?.toString().trim().isNotEmpty == true
              ? fields['businessCategory'].toString()
              : fields['jobCategory']?.toString().trim().isNotEmpty == true
              ? fields['jobCategory'].toString()
              : fields['professionTitle']?.toString().trim().isNotEmpty == true
              ? fields['professionTitle'].toString()
              : fields['businessSector']?.toString().trim().isNotEmpty == true
              ? fields['businessSector'].toString()
              : 'Professionnel';
          final city = fields['cityAddress']?.toString() ?? '';
          final openingHours = fields['openingHours']?.toString() ?? '';
          final status = data['status']?.toString() ?? 'pendingApproval';
          final isVerified = data['isVerified'] == true;
          final normalizedCategory = category.toLowerCase();
          final isEmployer = sourceCollection == 'employerSubmissions';
          final isRestaurant =
              sourceCollection == 'businessSubmissions' &&
              (normalizedCategory.contains('restaurant') ||
                  normalizedCategory.contains('café') ||
                  normalizedCategory.contains('cafe') ||
                  normalizedCategory.contains('catering') ||
                  normalizedCategory.contains('bakery'));
          final legacyRoomLayout =
              sourceCollection == 'businessSubmissions' &&
              (isRestaurant || normalizedCategory.contains('event venue'));
          final tableChoice = data['tableReservationsEnabled'];
          final hasRoomLayout =
              supportsTableReservations(sourceCollection) &&
              (tableChoice is bool ? tableChoice : legacyRoomLayout);
          final supportsServices = !isEmployer;
          final supportsAppointments =
              !isEmployer && supportsTableReservations(sourceCollection);

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (profiles.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(profile.key),
                    initialValue: profile.key,
                    dropdownColor: cardGreen,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Choisir mon établissement ou service',
                      labelStyle: const TextStyle(color: primaryGold),
                      prefixIcon: const Icon(
                        Icons.storefront,
                        color: primaryGold,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryGold),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryGold,
                          width: 2,
                        ),
                      ),
                    ),
                    items: profiles.map((p) {
                      final info = p.document.data();
                      final f = Map<String, dynamic>.from(
                        info['fields'] ?? <String, dynamic>{},
                      );
                      final name =
                          (f['title'] ??
                                  info['businessName'] ??
                                  'Établissement / Service')
                              .toString();
                      return DropdownMenuItem<String>(
                        value: p.key,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (key) =>
                        setState(() => _selectedBusinessKey = key),
                  ),
                ),
              _BusinessHeader(
                businessId: document.id,
                sourceCollection: sourceCollection,
                businessName: businessName,
                category: category,
                city: city,
                status: status,
                isVerified: isVerified,
                logoUrl: data['logoUrl']?.toString() ?? '',
                coverUrl: data['coverUrl']?.toString() ?? '',
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: !isEmployer
                    ? _ProfessionalVerificationCard(
                        businessId: document.id,
                        sourceCollection: sourceCollection,
                        status: status,
                        isVerified: isVerified,
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),
              if (!isEmployer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Material(
                    color: cardGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: primaryGold, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        if (!['approved', 'published'].contains(status)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Votre établissement doit être publié avant de demander une promotion.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => AdvertisementRequestScreen(
                              sourceCollection: sourceCollection,
                              businessId: document.id,
                              businessName: businessName,
                            ),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              color: primaryGold,
                              size: 32,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Promouvoir mon établissement',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Photo, offre et aperçu · demande sans paiement',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: primaryGold),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (!isEmployer)
                ProfessionalMembershipAction(
                  sourceCollection: sourceCollection,
                  businessId: document.id,
                  businessName: businessName,
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AdaptiveDashboardGrid(
                  children: [
                    if (isEmployer)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Profil employeur enregistré. Les outils de gestion des offres et candidatures seront connectés prochainement.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    if (!isEmployer)
                      _DashboardButton(
                        icon: Icons.edit_outlined,
                        title: 'Modifier mes infos',
                        subtitle: 'Nom, téléphone, adresse et description',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessEditProfileScreen(
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                              ),
                            ),
                          );
                          if (mounted) {
                            _refreshProfiles();
                          }
                        },
                      ),
                    if (!isEmployer)
                      _DashboardButton(
                        icon: Icons.photo_library_outlined,
                        title: 'Photos & Galerie',
                        subtitle: 'Logo, couverture et photos',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessGalleryScreen(
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                              ),
                            ),
                          );
                        },
                      ),
                    if (!isEmployer)
                      _DashboardButton(
                        icon: Icons.access_time,
                        title: 'Horaires',
                        subtitle: openingHours.isEmpty
                            ? 'Ajouter les horaires'
                            : openingHours,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessHoursScreen(
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                              ),
                            ),
                          );
                        },
                      ),
                    if (isRestaurant)
                      _DashboardButton(
                        icon: Icons.receipt_long_outlined,
                        title: 'Commandes',
                        subtitle: 'Voir et gérer les commandes clients',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessOrdersScreen(
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                              ),
                            ),
                          );
                        },
                      ),
                    if (!isEmployer &&
                        const [
                          'businessSubmissions',
                          'jobSubmissions',
                        ].contains(sourceCollection))
                      _DashboardButton(
                        icon: Icons.insights_outlined,
                        title: 'Mes ventes et statistiques',
                        subtitle:
                            'Commandes, ventes déclarées et frais enregistrés',
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ProfessionalSalesScreen(
                              businessId: document.id,
                              sourceCollection: sourceCollection,
                              businessName: businessName,
                            ),
                          ),
                        ),
                      ),
                    if (!isEmployer)
                      _DashboardButton(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Paiements et versements',
                        subtitle:
                            'Choisir les moyens de paiement de cet établissement',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfessionalPaymentsScreen(
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                                businessName: businessName,
                              ),
                            ),
                          );
                        },
                      ),
                    if (supportsServices)
                      _DashboardButton(
                        icon: Icons.design_services_outlined,
                        title: 'Services / Menu',
                        subtitle: 'Gérer vos services, produits ou menu',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BusinessMenuManagementScreen(
                                    businessId: document.id,
                                    sourceCollection: sourceCollection,
                                  ),
                            ),
                          );
                        },
                      ),
                    if (supportsAppointments)
                      _DashboardButton(
                        icon: Icons.event_available_outlined,
                        title: 'Gérer les rendez-vous',
                        subtitle:
                            'Prestations, disponibilités et demandes clients',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfessionalAppointmentsScreen(
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                                businessName: businessName,
                              ),
                            ),
                          );
                        },
                      ),
                    if (hasRoomLayout)
                      _DashboardButton(
                        icon: Icons.table_restaurant_outlined,
                        title: 'Gestion des salles et tables',
                        subtitle: 'Gérer les salles et enregistrer les tables',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomLayoutEditorScreen(
                                businessName: businessName,
                                businessId: document.id,
                                sourceCollection: sourceCollection,
                              ),
                            ),
                          );
                        },
                      ),
                    if (hasRoomLayout)
                      _DashboardButton(
                        icon: Icons.event_available_outlined,
                        title: 'Réservations de tables',
                        subtitle: 'Accepter ou refuser les demandes',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessTableReservationsScreen(
                              businessId: document.id,
                              sourceCollection: sourceCollection,
                            ),
                          ),
                        ),
                      ),
                    if (!isEmployer)
                      _DashboardButton(
                        icon: Icons.visibility_outlined,
                        title: 'Voir ma page publique',
                        subtitle:
                            'Voir votre entreprise comme les utilisateurs',
                        highlighted: true,
                        onTap: () async {
                          if (sourceCollection == 'jobSubmissions') {
                            final jobCategory =
                                fields['jobCategory']?.toString() ?? category;
                            final previewData = <String, dynamic>{
                              ...data,
                              ...fields,
                              // Identifiants
                              'sourceCollection': sourceCollection,
                              'sourceId': document.id,
                              'roomLayoutSourceCollection': sourceCollection,
                              'roomLayoutBusinessId': document.id,
                              'id': document.id,
                              'documentId': document.id,
                              // Présentation
                              'name': businessName,
                              'title': jobCategory,
                              'jobCategory': jobCategory,
                              'category': jobCategory,
                              // Catering
                              'serviceType':
                                  (data['serviceType'] ?? jobCategory)
                                      .toString(),
                              'icon': Icons.work_outline,
                              // Coordonnées
                              'description':
                                  fields['description']?.toString() ?? '',
                              'phone': fields['phoneNumber']?.toString() ?? '',
                              'phoneNumber':
                                  fields['phoneNumber']?.toString() ?? '',
                              'email':
                                  fields['emailAddress']?.toString() ??
                                  data['submitterEmail']?.toString() ??
                                  '',
                              'website': fields['websiteUrl']?.toString() ?? '',
                              'websiteUrl':
                                  fields['websiteUrl']?.toString() ?? '',
                              'location':
                                  fields['cityAddress']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? fields['cityAddress'].toString()
                                  : fields['country']?.toString() ?? '',
                              'cityAddress':
                                  fields['cityAddress']?.toString() ?? '',
                              'country': fields['country']?.toString() ?? '',
                              'whatsapp':
                                  fields['phoneNumber']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? 'https://wa.me/${fields['phoneNumber'].toString().replaceAll(RegExp(r'[^0-9]'), '')}'
                                  : '',
                              // Images
                              'logoUrl': data['logoUrl']?.toString() ?? '',
                              'coverUrl': data['coverUrl']?.toString() ?? '',
                              'gallery': data['gallery'] is List
                                  ? data['gallery']
                                  : <dynamic>[],
                              // Menu
                              'menuItems': data['menuItems'] is List
                                  ? data['menuItems']
                                  : <dynamic>[],
                              // Affichage
                              'rating':
                                  data['rating']?.toString() ?? '5.0 (New)',
                              'reviews': data['reviews'] is List
                                  ? data['reviews']
                                  : <dynamic>[],
                              // Propriétaire
                              'submittedBy':
                                  data['submittedBy']?.toString() ?? '',
                              'ownerId': data['ownerId']?.toString() ?? '',
                              'creatorId': data['creatorId']?.toString() ?? '',
                              'status':
                                  data['status']?.toString() ?? 'published',
                              'isVerified': data['isVerified'] == true,
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JobDetailScreen(jobData: previewData),
                              ),
                            );
                            return;
                          }
                          await _openPublishedBusiness(
                            document,
                            sourceCollection,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BusinessHeader extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  final String businessName;
  final String category;
  final String city;
  final String status;
  final bool isVerified;
  final String logoUrl;
  final String coverUrl;
  const _BusinessHeader({
    required this.businessId,
    required this.sourceCollection,
    required this.businessName,
    required this.category,
    required this.city,
    required this.status,
    required this.isVerified,
    required this.logoUrl,
    required this.coverUrl,
  });
  @override
  State<_BusinessHeader> createState() => _BusinessHeaderState();
}

class _BusinessHeaderState extends State<_BusinessHeader> {
  final ImagePicker _picker = ImagePicker();
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  late String _logoUrl;
  late String _coverUrl;
  @override
  void initState() {
    super.initState();
    _logoUrl = widget.logoUrl;
    _coverUrl = widget.coverUrl;
  }

  // EH_CADRAGE_AVIS_V1
  Future<void> _changeImage({required bool isLogo}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: isLogo ? 1000 : 1800,
      );
      if (image == null) {
        return;
      }
      final originalBytes = await image.readAsBytes();
      if (!mounted) { return; }
      final framedBytes = await frameProfessionalPhoto(context, bytes: originalBytes,
        use: isLogo ? ProfessionalPhotoUse.logo : ProfessionalPhotoUse.cover);
      if (!mounted || framedBytes == null) { return; }
      setState(() {
        if (isLogo) {
          _uploadingLogo = true;
        } else {
          _uploadingCover = true;
        }
      });
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté.');
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = isLogo
          ? 'businesses/${user.uid}/profile_$fileName'
          : 'businesses/${user.uid}/cover_$fileName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      await storageRef.putData(
        framedBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId)
          .update({
            isLogo ? 'logoUrl' : 'coverUrl': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await ProfessionalProfileSyncService.syncPublishedProfile(
        sourceCollection: widget.sourceCollection,
        sourceId: widget.businessId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (isLogo) {
          _logoUrl = downloadUrl;
        } else {
          _coverUrl = downloadUrl;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogo ? 'Logo mis à jour.' : 'Photo de couverture mise à jour.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’enregistrer la photo : $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingLogo = false;
          _uploadingCover = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    switch (widget.status) {
      case 'approved':
      case 'published':
        statusText = 'Profil publié';
        break;
      case 'rejected':
        statusText = 'Profil refusé';
        break;
      default:
        statusText = 'En attente de validation';
    }
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // =========================
            // PHOTO DE COUVERTURE
            // =========================
            GestureDetector(
              onTap: _uploadingCover ? null : () => _changeImage(isLogo: false),
              child: Stack(
                children: [
                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00695C), Color(0xFF003D33)],
                      ),
                      image: _coverUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_coverUrl),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child: _coverUrl.isEmpty
                        ? const Icon(
                            Icons.storefront,
                            size: 70,
                            color: Colors.white12,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _uploadingCover
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Couverture',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // =========================
            // LOGO / PHOTO DE PROFIL
            // =========================
            Positioned(
              bottom: -48,
              child: GestureDetector(
                onTap: _uploadingLogo ? null : () => _changeImage(isLogo: true),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: BusinessDashboardScreen.cardGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BusinessDashboardScreen.primaryGold,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 12),
                        ],
                        image: _logoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_logoUrl),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: _uploadingLogo
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: BusinessDashboardScreen.primaryGold,
                              ),
                            )
                          : _logoUrl.isEmpty
                          ? const Icon(
                              Icons.business,
                              color: BusinessDashboardScreen.primaryGold,
                              size: 44,
                            )
                          : null,
                    ),
                    Positioned(
                      right: -3,
                      bottom: 2,
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: BusinessDashboardScreen.primaryGold,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: BusinessDashboardScreen.primaryDarkGreen,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: BusinessDashboardScreen.primaryDarkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 62),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.businessName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.isVerified) ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.verified,
                      color: BusinessDashboardScreen.primaryGold,
                      size: 21,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Text(
                widget.city.isEmpty
                    ? widget.category
                    : '${widget.category} • ${widget.city}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: BusinessDashboardScreen.cardGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: BusinessDashboardScreen.primaryGold.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: BusinessDashboardScreen.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element — conservé pour la future vérification professionnelle
class _ProfessionalVerificationCard extends StatelessWidget {
  final String businessId;
  final String sourceCollection;
  final String status;
  final bool isVerified;
  const _ProfessionalVerificationCard({
    required this.businessId,
    required this.sourceCollection,
    required this.status,
    required this.isVerified,
  });
  @override
  Widget build(BuildContext context) {
    final bool pending = status == 'pending' || status == 'pendingApproval';
    final String title = isVerified
        ? 'Professionnel vérifié'
        : pending
        ? 'Vérification en cours'
        : 'Vérification professionnelle';
    final String subtitle = isVerified
        ? 'Votre établissement est vérifié.'
        : pending
        ? 'Votre dossier est en attente de validation administrative.'
        : 'Vérifiez votre établissement pour obtenir le badge Verified.';
    return Material(
      color: BusinessDashboardScreen.cardGreen,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalVerificationScreen(
                businessId: businessId,
                sourceCollection: sourceCollection,
                currentStatus: status,
                isVerified: isVerified,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: BusinessDashboardScreen.primaryGold.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isVerified ? Icons.verified : Icons.verified_user_outlined,
                  color: BusinessDashboardScreen.primaryGold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isVerified ? Icons.check_circle : Icons.arrow_forward_ios,
                size: isVerified ? 20 : 15,
                color: BusinessDashboardScreen.primaryGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Grille responsive : 2 colonnes sur telephone, 3 sur petite tablette,
// 4 sur grande tablette / ordinateur. Chaque carte conserve son onTap.
class _AdaptiveDashboardGrid extends StatelessWidget {
  final List<Widget> children;
  const _AdaptiveDashboardGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 4
            : width >= 580
            ? 3
            : 2;
        const gap = 12.0;
        final tileWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map(
                (child) => SizedBox(
                  width: tileWidth,
                  height: width < 380 ? 136 : 148,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  const _DashboardButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    const dark = BusinessDashboardScreen.primaryDarkGreen;
    const gold = BusinessDashboardScreen.primaryGold;
    return Material(
      color: highlighted ? gold : BusinessDashboardScreen.cardGreen,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: highlighted ? dark : dark.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: gold.withValues(alpha: .45)),
                ),
                child: Icon(icon, color: gold, size: 25),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: highlighted ? dark : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: highlighted
                      ? dark.withValues(alpha: .75)
                      : Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnedProfessionalProfile {
  final String collection;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  const _OwnedProfessionalProfile(this.collection, this.document);
  String get key => '$collection/${document.id}';
}
