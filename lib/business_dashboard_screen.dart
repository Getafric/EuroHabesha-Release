import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'business_orders_screen.dart';
import 'business_menu_management_screen.dart';
import 'notifications_screen.dart';
import 'business_edit_profile_screen.dart';
import 'business_gallery_screen.dart';
import 'business_hours_screen.dart';
import 'jobs_screen.dart';
import 'professional_profile_sync_service.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

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

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
        title: const Text(
          'Mon Entreprise',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('businessSubmissions')
            .where('ownerId', isEqualTo: user.uid)
            .limit(1)
            .get()
            .then((businessSnapshot) async {
          if (businessSnapshot.docs.isNotEmpty) {
            return businessSnapshot;
          }

          return FirebaseFirestore.instance
              .collection('jobSubmissions')
              .where('ownerId', isEqualTo: user.uid)
              .limit(1)
              .get();
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun profil entreprise trouvé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          final document = snapshot.data!.docs.first;
          final data = document.data();
          final sourceCollection = data['fields']?['jobCategory'] != null
              ? 'jobSubmissions'
              : 'businessSubmissions';
          final fields =
              Map<String, dynamic>.from(data['fields'] ?? <String, dynamic>{});

          final businessName =
              fields['title']?.toString().trim().isNotEmpty == true
                  ? fields['title'].toString()
                  : 'Mon Entreprise';

          final category =
              fields['businessCategory']?.toString().trim().isNotEmpty == true
                  ? fields['businessCategory'].toString()
                  : fields['jobCategory']?.toString().trim().isNotEmpty == true
                      ? fields['jobCategory'].toString()
                      : 'Professionnel';

          final city = fields['cityAddress']?.toString() ?? '';

          final openingHours = fields['openingHours']?.toString() ?? '';

          final status = data['status']?.toString() ?? 'pendingApproval';

          final isVerified = data['isVerified'] == true;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
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
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
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
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.design_services_outlined,
                      title: 'Services / Menu',
                      subtitle: 'Gérer vos services, produits ou menu',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessMenuManagementScreen(
                              businessId: document.id,
                              sourceCollection: sourceCollection,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.visibility_outlined,
                      title: 'Voir ma page publique',
                      subtitle: 'Voir votre entreprise comme les utilisateurs',
                      highlighted: true,
                      onTap: () {
                        if (sourceCollection == 'jobSubmissions') {
                          final jobCategory =
                              fields['jobCategory']?.toString() ?? category;

                          final previewData = <String, dynamic>{
                            ...data,
                            ...fields,

                            // Identifiants
                            'id': document.id,
                            'documentId': document.id,

                            // Présentation
                            'name': businessName,
                            'title': jobCategory,
                            'jobCategory': jobCategory,
                            'category': jobCategory,

                            // Catering
                            'serviceType': 'catering',
                            'icon': Icons.restaurant,

                            // Coordonnées
                            'description':
                                fields['description']?.toString() ?? '',
                            'phone': fields['phoneNumber']?.toString() ?? '',
                            'phoneNumber':
                                fields['phoneNumber']?.toString() ?? '',
                            'email': fields['emailAddress']?.toString() ??
                                data['submitterEmail']?.toString() ??
                                '',
                            'website': fields['websiteUrl']?.toString() ?? '',
                            'websiteUrl':
                                fields['websiteUrl']?.toString() ?? '',
                            'location': fields['cityAddress']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true
                                ? fields['cityAddress'].toString()
                                : fields['country']?.toString() ?? '',
                            'cityAddress':
                                fields['cityAddress']?.toString() ?? '',
                            'country': fields['country']?.toString() ?? '',

                            'whatsapp': fields['phoneNumber']
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
                            'rating': data['rating']?.toString() ?? '5.0 (New)',
                            'reviews': data['reviews'] is List
                                ? data['reviews']
                                : <dynamic>[],

                            // Propriétaire
                            'submittedBy':
                                data['submittedBy']?.toString() ?? '',
                            'ownerId': data['ownerId']?.toString() ?? '',
                            'creatorId': data['creatorId']?.toString() ?? '',

                            'status': data['status']?.toString() ?? 'published',
                            'isVerified': data['isVerified'] == true,
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(
                                jobData: previewData,
                              ),
                            ),
                          );

                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La page publique Entreprise sera connectée séparément.',
                            ),
                          ),
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

  Future<void> _changeImage({
    required bool isLogo,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: isLogo ? 1000 : 1800,
      );

      if (image == null) {
        return;
      }

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

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storagePath = isLogo
          ? 'businesses/${user.uid}/profile_$fileName'
          : 'businesses/${user.uid}/cover_$fileName';

      final storageRef = FirebaseStorage.instance.ref(storagePath);

      await storageRef.putFile(
        File(image.path),
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
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
        SnackBar(
          content: Text(
            'Impossible d’enregistrer la photo : $error',
          ),
        ),
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
                        colors: [
                          Color(0xFF00695C),
                          Color(0xFF003D33),
                        ],
                      ),
                      image: _coverUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_coverUrl),
                              fit: BoxFit.cover,
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
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 12,
                          ),
                        ],
                        image: _logoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_logoUrl),
                                fit: BoxFit.cover,
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
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
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
                    color: BusinessDashboardScreen.primaryGold
                        .withValues(alpha: 0.35),
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
    return Material(
      color: highlighted
          ? BusinessDashboardScreen.primaryGold
          : BusinessDashboardScreen.cardGreen,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: highlighted
                      ? BusinessDashboardScreen.primaryDarkGreen
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
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
                      style: TextStyle(
                        color: highlighted
                            ? BusinessDashboardScreen.primaryDarkGreen
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: highlighted
                            ? BusinessDashboardScreen.primaryDarkGreen
                                .withValues(alpha: 0.7)
                            : Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: highlighted
                    ? BusinessDashboardScreen.primaryDarkGreen
                    : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
