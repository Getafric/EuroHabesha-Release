import 'dart:io';
import 'admin_fees_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'advertisement_request_screen.dart';
import 'app_session.dart';
import 'admin_banner_screen.dart';
import 'admin_universal_content_manager_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  late TabController _tabController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // QUICK POST & REGIONS CONFIGURATION
  // ===========================================================================

  final Map<String, String> countryPhoneCodes = {
    'France': '+33',
    'Belgium': '+32',
    'UK': '+44',
    'Netherlands': '+31',
    'Portugal': '+351',
    'Spain': '+34',
    'Italy': '+39',
    'Switzerland': '+41',
    'Finland': '+358',
    'Norway': '+47',
    'Sweden': '+46',
    'Denmark': '+45',
    'Germany': '+49',
    'Greece': '+30',
    'Poland': '+48',
    'Hungary': '+36',
    'Austria': '+43',
    'Bulgaria': '+359',
    'Romania': '+40',
    'Luxembourg': '+352',
    'Turkey': '+90',
  };

  late String selectedCountry;
  String phonePrefix = '+33';

  String selectedCategory = 'Business / Restaurant';

  final List<String> categories = [
    'Business / Restaurant',
    'Marketplace Item',
    'Job Listing',
    'Community Event',
  ];

  File? _businessLogo;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _mapLinkController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // ===========================================================================
  // ADMIN INVITES & PERMISSIONS CONFIGURATION
  // ===========================================================================

  final TextEditingController _inviteEmailController = TextEditingController();

  final TextEditingController _accessCodeController =
      TextEditingController(text: '7124');

  String selectedInviteRole = 'Habesha Connect Admin';

  final List<String> inviteRoles = [
    'Habesha Connect Admin',
    'Jobs Admin',
    'Businesses Admin',
    'Marketplace Admin',
    'Events Admin',
    'Professionals Admin',
    'Moderator',
    'Editor',
    'Helper',
  ];

  String selectedInviteScope = 'Groupes & Associations';

  final List<String> availableScopes = [
    'Groupes & Associations',
    'Habesha par ville',
    'Entraide',
    'Logement',
    'Transport & déplacement',
    'Aide administrative',
    'Langues & traduction',
    'Études & formation',
    'Familles & parents',
    'Carrière & mentorat',
    'Culture & rencontres',
    'Bénévolat & solidarité',
    'Jobs & Employment',
    'Businesses & Services',
    'Marketplace',
    'Events',
    'Professionals',
  ];

  // ===========================================================================
  // INIT & DISPOSE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: AppSession.isSuperAdmin ? 8 : 1,
      vsync: this,
    );

    selectedCountry = countryPhoneCodes.keys.first;
    phonePrefix = countryPhoneCodes[selectedCountry]!;

    _phoneController.text = '$phonePrefix ';
  }

  @override
  void dispose() {
    _tabController.dispose();

    _titleController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _mapLinkController.dispose();
    _descController.dispose();

    _inviteEmailController.dispose();
    _accessCodeController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // HELPER METHODS & SYSTEM UTILITIES
  // ===========================================================================

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  List<String> _permissionsForRole(String role) {
    return switch (role) {
      'Habesha Connect Admin' => [
          'manage_habesha_connect_category',
          'review_habesha_connect_requests',
          'publish_habesha_connect',
          'moderate_habesha_connect',
        ],
      'Jobs Admin' => [
          'manage_jobs',
          'review_jobs',
        ],
      'Businesses Admin' => [
          'manage_businesses',
          'review_businesses',
        ],
      'Marketplace Admin' => [
          'manage_marketplace',
          'review_marketplace',
        ],
      'Events Admin' => [
          'manage_events',
          'review_events',
          'scan_tickets',
        ],
      'Professionals Admin' => [
          'manage_professionals',
          'review_professionals',
        ],
      'Moderator' => [
          'review_comments',
          'hide_content',
          'moderate_content',
        ],
      'Editor' => [
          'review_submissions',
          'edit_content',
        ],
      'Helper' => [
          'view_dashboard',
          'respond_support',
        ],
      _ => [
          'view_dashboard',
        ],
    };
  }

  // ===========================================================================
  // ADMIN INVITE & MANAGEMENT SECTION
  // ===========================================================================

  Future<void> _sendAdminInvite() async {
    if (!AppSession.isSuperAdmin) {
      _showMessage(
        'Seul le Super Admin peut créer un administrateur.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final email = _inviteEmailController.text.trim().toLowerCase();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage(
        'Veuillez saisir une adresse e-mail valide.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final accessCode = _accessCodeController.text.trim();

    if (accessCode.length < 4) {
      _showMessage(
        'Le code d’accès doit contenir au moins 4 chiffres.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    try {
      // Vérifie si cette catégorie possède déjà un administrateur actif.
      final activeAdmins = await _firestore
          .collection('adminInvites')
          .where('status', isEqualTo: 'active')
          .limit(100)
          .get();

      final alreadyExists = activeAdmins.docs.any((doc) {
        return doc.data()['scope']?.toString() == selectedInviteScope;
      });

      if (alreadyExists) {
        _showMessage(
          'Cette catégorie possède déjà un administrateur actif.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      // Recherche le compte Euro Habesha correspondant à l'e-mail.
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        _showMessage(
          'Aucun compte Euro Habesha trouvé avec cet e-mail.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final invitedUser = usersSnapshot.docs.first;
      final invitedUserId = invitedUser.id;

      // L'e-mail reste l'identifiant du document pour rester compatible
      // avec le système AdminPasscodeScreen existant.
      final inviteRef = _firestore.collection('adminInvites').doc(email);

      await inviteRef.set({
        'email': email,
        'invitedUserId': invitedUserId,
        'role': selectedInviteRole,
        'scope': selectedInviteScope,
        'accessCode': accessCode,
        'status': 'pending',
        'invitedBy': AppSession.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'permissions': _permissionsForRole(selectedInviteRole),
      });

      // Cette notification Firestore sera récupérée par la Cloud Function
      // sendNotificationPush déjà présente dans functions/index.js.
      await _firestore.collection('notifications').add({
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'recipientId': invitedUserId,
        'userId': invitedUserId,
        'title': 'Invitation administrateur',
        'body':
            'Vous êtes invité à devenir $selectedInviteRole pour $selectedInviteScope.',
        'type': 'admin',
        'routeType': 'adminInvite',
        'resourceId': email,
        'isRead': false,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _inviteEmailController.clear();
      _accessCodeController.clear();

      _showMessage(
        'Invitation envoyée à $email.',
        backgroundColor: cardGreen,
      );
    } catch (error) {
      _showMessage(
        'Erreur lors de l’envoi de l’invitation : $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Widget _buildActiveAdmins() {
    if (!AppSession.isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('adminInvites')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildAdminMessage(
            'Impossible de charger les administrateurs : ${snapshot.error}',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              'Administrateurs actifs',
              style: TextStyle(
                color: primaryGold,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (docs.isEmpty)
              _buildAdminMessage(
                'Aucun administrateur secondaire actif.',
              )
            else
              ...docs.map(_buildAdminCard),
          ],
        );
      },
    );
  }

  Widget _buildAdminCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final email = data['email']?.toString() ?? doc.id;
    final role = data['role']?.toString() ?? 'Admin';
    final scope = data['scope']?.toString() ?? 'Non défini';

    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: primaryGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    role,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Désactiver',
                  icon: const Icon(
                    Icons.person_off,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _disableAdmin(doc),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              email,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Catégorie : $scope',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disableAdmin(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          title: const Text(
            'Désactiver cet administrateur ?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            doc.data()?['email']?.toString() ?? doc.id,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Désactiver',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await doc.reference.update({
        'status': 'disabled',
        'disabledAt': FieldValue.serverTimestamp(),
        'disabledBy': AppSession.email,
      });

      _showMessage(
        'Administrateur désactivé.',
        backgroundColor: cardGreen,
      );
    } catch (error) {
      _showMessage(
        'Erreur : $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  // ===========================================================================
  // HABESHA CONNECT MODERATION SECTION
  // ===========================================================================

  Widget _buildHabeshaConnectRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('habeshaConnectRequests')
          .where('status', isEqualTo: 'pending')
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildAdminMessage(
            'Erreur Habesha Connect : ${snapshot.error}',
          );
        }

        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snapshot.data?.docs ?? [],
        );

        docs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          if (aTime is Timestamp) return -1;
          if (bTime is Timestamp) return 1;

          return 0;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habesha Connect — Demandes en attente',
              style: TextStyle(
                color: primaryGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les demandes restent invisibles au public jusqu’à leur approbation.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 15),
            if (docs.isEmpty)
              _buildAdminMessage(
                'Aucune demande Habesha Connect en attente.',
              )
            else
              ...docs.map(_buildConnectRequestCard),
          ],
        );
      },
    );
  }

  Widget _buildConnectRequestCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final category = data['category']?.toString() ?? 'Non classé';
    final question =
        data['question']?.toString() ?? data['text']?.toString() ?? '';
    final city = data['city']?.toString() ?? '';
    final country = data['country']?.toString() ?? '';
    final authorName = data['authorName']?.toString() ?? 'Utilisateur';
    final authorEmail = data['authorEmail']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';

    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryGold.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: primaryGold,
                  child: Icon(
                    Icons.groups,
                    color: primaryDarkGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (question.isNotEmpty)
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            if (city.isNotEmpty || country.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white54,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      [
                        if (city.isNotEmpty) city,
                        if (country.isNotEmpty) country,
                      ].join(', '),
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Demandé par : $authorName',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            if (authorEmail.isNotEmpty)
              Text(
                authorEmail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _approveButton(doc),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _rejectButton(doc),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () => _deleteConnectRequest(doc),
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Supprimer',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _approveButton(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
      ),
      onPressed: () => _reviewConnectRequest(
        doc,
        approved: true,
      ),
      icon: Icon(
        Icons.check_circle,
        color: primaryDarkGreen,
      ),
      label: Text(
        'APPROUVER',
        style: TextStyle(
          color: primaryDarkGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _rejectButton(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
      onPressed: () => _reviewConnectRequest(
        doc,
        approved: false,
      ),
      icon: const Icon(
        Icons.cancel,
        color: Colors.white,
      ),
      label: const Text(
        'REFUSER',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _reviewConnectRequest(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool approved,
  }) async {
    final reviewer = _auth.currentUser;
    final data = doc.data() ?? {};

    if (reviewer == null) {
      _showMessage(
        'Session administrateur introuvable.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final newStatus = approved ? 'approved' : 'rejected';

    try {
      await doc.reference.update({
        'status': newStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewer.uid,
        'reviewedByEmail': reviewer.email ?? AppSession.email,
      });

      if (approved) {
        await _publishApprovedConnectRequest(
          doc.id,
          data,
          reviewer.uid,
        );
      }

      _showMessage(
        approved
            ? 'Demande approuvée et publiée dans le Feed.'
            : 'Demande refusée.',
        backgroundColor: approved ? cardGreen : Colors.orange,
      );
    } catch (error) {
      _showMessage(
        'Erreur lors de la modération : $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _publishApprovedConnectRequest(
    String requestId,
    Map<String, dynamic> data,
    String reviewerUid,
  ) async {
    final category = data['category']?.toString() ?? 'Entraide';
    final authorId = data['authorId']?.toString() ?? '';
    final authorName = data['authorName']?.toString() ?? 'Membre Habesha';
    final authorEmail = data['authorEmail']?.toString() ?? '';
    final question =
        data['question']?.toString() ?? data['text']?.toString() ?? '';
    final city = data['city']?.toString() ?? '';
    final country = data['country']?.toString() ?? '';

    final postRef = _firestore.collection('posts').doc();

    await postRef.set({
      'source': 'habeshaConnect',
      'sourceRequestId': requestId,
      'connectCategory': category,
      'category': category,
      'text': question,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'city': city,
      'country': country,
      'location': city,
      'status': 'published',
      'ownerId': authorId,
      'isDemo': false,
      'createdAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
      'approvedBy': reviewerUid,
      'likeCount': 0,
      'commentCount': 0,
    });

    await _firestore
        .collection('publicFeed')
        .doc('habeshaConnect_$requestId')
        .set({
      'sourceCollection': 'habeshaConnectRequests',
      'sourceId': requestId,
      'type': data['type'],
      'postId': postRef.id,
      'source': 'habeshaConnect',
      'status': 'published',
      'category': category,
      'title': category,
      'subtitle': city,
      'description': question,
      'submittedBy': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'country': country,
      'isDemo': false,
      'publishedAt': FieldValue.serverTimestamp(),
      'approvedBy': reviewerUid,
    }, SetOptions(merge: true));

    await _firestore
        .collection('habeshaConnectRequests')
        .doc(requestId)
        .update({
      'publishedPostId': postRef.id,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteConnectRequest(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          title: const Text(
            'Supprimer cette demande ?',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'La demande sera supprimée définitivement.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await doc.reference.delete();
      _showMessage(
        'Demande supprimée.',
        backgroundColor: cardGreen,
      );
    } catch (error) {
      _showMessage(
        'Erreur : $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  // ===========================================================================
  // DASHBOARD NAVIGATION & BOTTOM SHEETS
  // ===========================================================================

  Future<void> _openHabeshaConnectManagement() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: primaryDarkGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.88,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups,
                        color: primaryGold,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Habesha Connect',
                          style: TextStyle(
                            color: primaryGold,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white12,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      30,
                    ),
                    child: _buildHabeshaConnectRequests(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAdminsManagement() {
    _tabController.animateTo(7);
  }

  // ===========================================================================
  // ADVERTISEMENT REQUESTS MANAGEMENT SECTION
  // ===========================================================================

  Widget _buildAdvertisementRequests() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_business),
              label: const Text(
                'Créer une publicité pour une entreprise',
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvertisementRequestScreen(
                      isAdminCreated: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('advertisementRequests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Erreur : ${snapshot.error}'),
                );
              }

              final requests = snapshot.data?.docs ?? [];

              if (requests.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune demande de publicité en attente.',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final doc = requests[index];
                  final data = doc.data();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['businessName'] ?? 'Sans nom',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type : ${data['advertisementType'] ?? '-'}',
                          ),
                          Text(
                            'Durée : ${data['duration'] ?? '-'}',
                          ),
                          Text(
                            'Budget : ${data['budget'] ?? '-'}',
                          ),
                          Text(
                            'Email : ${data['userEmail'] ?? '-'}',
                          ),
                          const SizedBox(height: 8),
                          Text(data['description'] ?? ''),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _reviewAdvertisementRequest(
                                  doc.id,
                                  approved: false,
                                ),
                                child: const Text('Refuser'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _reviewAdvertisementRequest(
                                  doc.id,
                                  approved: true,
                                ),
                                child: const Text('Approuver'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _reviewAdvertisementRequest(
    String requestId, {
    required bool approved,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final requestRef =
          firestore.collection('advertisementRequests').doc(requestId);

      final requestSnapshot = await requestRef.get();

      if (!requestSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advertising request not found.'),
            ),
          );
        }
        return;
      }

      final data = requestSnapshot.data()!;

      if (!approved) {
        await requestRef.update({
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advertising request rejected.'),
            ),
          );
        }
        return;
      }

      final advertisementType = (data['advertisementType'] ?? 'Business')
          .toString()
          .trim()
          .toLowerCase();

      String targetType;

      if (advertisementType == 'event') {
        targetType = 'event';
      } else if (advertisementType == 'marketplace') {
        targetType = 'marketplace';
      } else {
        targetType = 'business';
      }

      final targetRoute = targetType == 'event'
          ? '/event'
          : targetType == 'marketplace'
              ? '/marketplace'
              : '/business';

      final businessName =
          (data['businessName'] ?? 'Sponsored Advertisement').toString().trim();

      final description = (data['description'] ?? '').toString().trim();

      final promotion = (data['promotion'] ?? '').toString().trim();

      final promoCode =
          (data['promoCode'] ?? '').toString().trim().toUpperCase();

      final startDate = data['startDate'];
      final endDate = data['endDate'];

      final bannerRef = firestore.collection('sponsoredBanners').doc();

      final batch = firestore.batch();

      batch.set(
        bannerRef,
        {
          'title': businessName,
          'body': description,
          'imageUrl': (data['imageUrl'] ?? '').toString(),
          'promoCode': promoCode,
          'discountPercent': 0,
          'discountText': promotion,
          'promotion': promotion,
          'usageLimit': 100,
          'claimsCount': 0,
          'businessName': businessName,
          'description': description,
          'targetType': (data['targetType'] ?? targetType).toString(),
          'targetId': (data['targetId'] ?? '').toString(),
          'targetName': (data['targetName'] ?? businessName).toString(),
          'targetData': data['targetData'] is Map
              ? Map<String, dynamic>.from(
                  data['targetData'],
                )
              : <String, dynamic>{},
          'targetRoute': targetRoute,
          'targetBusinessId': targetType == 'business'
              ? (data['targetId'] ?? '').toString()
              : '',
          'targetBusinessName': targetType == 'business'
              ? (data['targetName'] ?? businessName).toString()
              : '',
          'targetBusinessData':
              targetType == 'business' && data['targetData'] is Map
                  ? Map<String, dynamic>.from(
                      data['targetData'],
                    )
                  : <String, dynamic>{},
          'startsAt': startDate is Timestamp ? startDate : Timestamp.now(),
          'endsAt': endDate is Timestamp
              ? endDate
              : Timestamp.fromDate(
                  DateTime.now().add(
                    const Duration(days: 30),
                  ),
                ),
          'status': 'active',
          'source': 'advertisementRequest',
          'sourceRequestId': requestId,
          'createdBy':
              (data['createdByEmail'] ?? data['userEmail'] ?? '').toString(),
          'createdByUserId':
              (data['createdByUserId'] ?? data['userId'] ?? '').toString(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        requestRef,
        {
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
          'sponsoredBannerId': bannerRef.id,
        },
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Advertising approved and banner published.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to review advertising request: $error',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // MAIN BUILD & TAB BAR VIEW
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = AppSession.isSuperAdmin;
    final roles = AppSession.roles.toSet();

    _ReviewCollection? delegatedCollection;

    if (!isSuperAdmin) {
      if (roles.contains('manage_events') || roles.contains('review_events')) {
        delegatedCollection = const _ReviewCollection(
          'Event Submissions',
          'eventSubmissions',
        );
      } else if (roles.contains('manage_businesses') ||
          roles.contains('review_businesses')) {
        delegatedCollection = const _ReviewCollection(
          'Business Submissions',
          'businessSubmissions',
        );
      } else if (roles.contains('manage_jobs') ||
          roles.contains('review_jobs')) {
        delegatedCollection = const _ReviewCollection(
          'Job / Service Submissions',
          'jobSubmissions',
        );
      } else if (roles.contains('manage_marketplace') ||
          roles.contains('review_marketplace')) {
        delegatedCollection = const _ReviewCollection(
          'Marketplace Submissions',
          'marketplaceSubmissions',
        );
      } else if (roles.contains('manage_professionals') ||
          roles.contains('review_professionals')) {
        delegatedCollection = const _ReviewCollection(
          'Professional Submissions',
          'jobSubmissions',
        );
      } else if (roles.contains('manage_habesha_connect_category') ||
          roles.contains('review_habesha_connect_requests')) {
        delegatedCollection = const _ReviewCollection(
          'Habesha Connect Submissions',
          'communitySubmissions',
        );
      }
    }

    final delegatedContent = delegatedCollection != null
        ? _buildSubmissionReviewTab([delegatedCollection])
        : _buildAdminMessage(
            'Aucune permission administrateur disponible.',
          );

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: primaryGold,
        ),
        title: Text(
          isSuperAdmin ? 'Admin Control Panel' : 'My Admin Panel',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isSuperAdmin,
          labelColor: primaryGold,
          unselectedLabelColor: Colors.white60,
          indicatorColor: primaryGold,
          tabs: isSuperAdmin
              ? const [
                  Tab(
                    icon: Icon(Icons.dashboard),
                    text: 'Dashboard',
                  ),
                  Tab(
                    icon: Icon(Icons.fact_check),
                    text: 'Submissions',
                  ),
                  Tab(
                    icon: Icon(Icons.verified_user),
                    text: 'Verifications',
                  ),
                  Tab(
                    icon: Icon(Icons.edit_note),
                    text: 'Quick Post',
                  ),
                  Tab(
                    icon: Icon(Icons.category),
                    text: 'Categories',
                  ),
                  Tab(
                    icon: Icon(Icons.campaign),
                    text: 'Banners',
                  ),
                  Tab(
                    icon: Icon(Icons.campaign_outlined),
                    text: 'Ad Requests',
                  ),
                  Tab(
                    icon: Icon(Icons.admin_panel_settings),
                    text: 'Admins',
                  ),
                ]
              : const [
                  Tab(
                    icon: Icon(Icons.admin_panel_settings),
                    text: 'My Category',
                  ),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isSuperAdmin
            ? [
                _buildDashboardTab(),
                _buildSubmissionReviewTab([
                  const _ReviewCollection(
                    'Business Submissions',
                    'businessSubmissions',
                  ),
                  const _ReviewCollection(
                    'Job / Service Submissions',
                    'jobSubmissions',
                  ),
                  const _ReviewCollection(
                    'Event Submissions',
                    'eventSubmissions',
                  ),
                  const _ReviewCollection(
                    'Marketplace Submissions',
                    'marketplaceSubmissions',
                  ),
                  const _ReviewCollection(
                    'Professional Submissions',
                    'professionalSubmissions',
                  ),
                ]),
                _buildSubmissionReviewTab(
                  [
                    const _ReviewCollection(
                      'Verification Requests',
                      'verificationRequests',
                    ),
                  ],
                  verificationMode: true,
                ),
                _buildAdminPostForm(),
                const AdminUniversalContentManagerScreen(),
                const AdminBannerScreen(),
                _buildAdvertisementRequests(),
                _buildInviteAdminForm(),
              ]
            : [
                delegatedContent,
              ],
      ),
    );
  }
  // ===========================================================================
  // DASHBOARD TAB WIDGETS
  // ===========================================================================

  Widget _buildDashboardTab() {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 30,
      ),
      children: [
        _buildDashboardHeader(),
        const SizedBox(height: 18),
        _buildHabeshaConnectRequests(),
        _buildQuickAdminStats(),
      ],
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardGreen,
            primaryDarkGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: primaryGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: primaryDarkGreen,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Euro Habesha',
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Super Admin Control Center',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdminStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          'Contrôle de la plateforme',
          style: TextStyle(
            color: primaryGold,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // Habesha Connect + Admins
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dashboardTile(
                Icons.groups,
                'Habesha Connect',
                'Demandes et communauté',
                onTap: _openHabeshaConnectManagement,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dashboardTile(
                Icons.admin_panel_settings,
                'Admins',
                'Permissions et catégories',
                onTap: _openAdminsManagement,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Frais & commissions
        Row(
          children: [
            Expanded(
              child: _dashboardTile(
                Icons.payments_outlined,
                'Frais & commissions',
                'Tickets, catering et services',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminFeesSettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dashboardTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 150,
          ),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: primaryGold.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: primaryGold,
                    size: 28,
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: primaryGold.withValues(alpha: 0.65),
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SUBMISSIONS REVIEW TAB & FIRESTORE HANDLING
  // ===========================================================================

  Widget _buildSubmissionReviewTab(
    List<_ReviewCollection> collections, {
    bool verificationMode = false,
  }) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        return _buildFirestoreReviewSection(
          collections[index],
          verificationMode: verificationMode,
        );
      },
    );
  }

  Widget _buildFirestoreReviewSection(
    _ReviewCollection reviewCollection, {
    bool verificationMode = false,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _firestore.collection(reviewCollection.collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildAdminMessage(
            '${reviewCollection.title}: ${snapshot.error}',
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final status = data['status']?.toString() ?? 'pendingApproval';

          final isPending = status == 'pendingApproval' ||
              status == 'pendingAdminReview' ||
              status == 'pendingPaymentAndReview' ||
              status == 'pending';

          if (!isPending) {
            return false;
          }
          if (!AppSession.isSuperAdmin &&
              reviewCollection.collectionName == 'jobSubmissions' &&
              (AppSession.roles.contains('manage_professionals') ||
                  AppSession.roles.contains('review_professionals')) &&
              !AppSession.roles.contains('manage_jobs') &&
              !AppSession.roles.contains('review_jobs')) {
            final submissionType =
                data['type']?.toString().trim().toLowerCase() ?? '';

            if (submissionType != 'professional') {
              return false;
            }
          }
          if (!AppSession.isSuperAdmin &&
              reviewCollection.collectionName == 'communitySubmissions') {
            final scopes = AppSession.roles
                .where((role) => role.startsWith('scoped:'))
                .map((role) => role.substring('scoped:'.length).trim())
                .where((scope) => scope.isNotEmpty)
                .toSet();

            if (scopes.isEmpty) {
              return false;
            }

            final fields = Map<String, dynamic>.from(
              data['fields'] ?? {},
            );

            final category = (data['category'] ??
                    data['scope'] ??
                    fields['category'] ??
                    fields['communityCategory'] ??
                    '')
                .toString()
                .trim();

            return scopes.contains(category);
          }

          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reviewCollection.title,
              style: TextStyle(
                color: primaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (docs.isEmpty)
              _buildAdminMessage(
                'Aucune demande en attente.',
              )
            else
              ...docs.map(
                (doc) => _buildSubmissionCard(
                  doc,
                  verificationMode: verificationMode,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSubmissionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    bool verificationMode = false,
  }) {
    final data = doc.data();

    final fields = Map<String, dynamic>.from(
      data['fields'] ?? {},
    );

    final badge = Map<String, dynamic>.from(
      data['verificationBadge'] ?? {},
    );

    final title = fields['title']?.toString().trim().isNotEmpty == true
        ? fields['title'].toString()
        : data['tierTitle']?.toString() ??
            data['type']?.toString() ??
            'Pending Submission';

    final subtitle = [
      if (fields['jobCategory'] != null) 'Category: ${fields['jobCategory']}',
      if (fields['country'] != null) 'Country: ${fields['country']}',
      if (fields['cityAddress'] != null) 'Address: ${fields['cityAddress']}',
      if (data['submitterEmail'] != null)
        'Submitted by: ${data['submitterEmail']}',
      if (badge['title'] != null)
        'Badge: ${badge['title']} ${badge['price'] ?? ''}',
      if (data['tierTitle'] != null)
        'Tier: ${data['tierTitle']} ${data['tierPrice'] ?? ''}',
    ].join('\n');

    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                  fontSize: 12,
                ),
              ),
            ],
            if (fields['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                fields['description'].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.4,
                  fontSize: 13,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSubmissionDetails(
                  doc,
                  verificationMode: verificationMode,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGold,
                  side: BorderSide(
                    color: primaryGold,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  Icons.visibility_outlined,
                  color: primaryGold,
                ),
                label: const Text(
                  'View Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _submissionApproveButton(
                    doc,
                    verificationMode,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _submissionRejectButton(
                    doc,
                    verificationMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () => _deleteSubmission(doc),
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Delete Permanently',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSubmissionDetails(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool verificationMode,
  }) async {
    final data = doc.data() ?? <String, dynamic>{};

    final fields = data['fields'] is Map
        ? Map<String, dynamic>.from(data['fields'] as Map)
        : <String, dynamic>{};

    final eventDetails = data['eventDetails'] is Map
        ? Map<String, dynamic>.from(data['eventDetails'] as Map)
        : <String, dynamic>{};

    final eventMedia = data['eventMedia'] is Map
        ? Map<String, dynamic>.from(data['eventMedia'] as Map)
        : <String, dynamic>{};

    final ticketTypes =
        data['ticketTypes'] is List ? data['ticketTypes'] as List : const [];

    final artists =
        data['artists'] is List ? data['artists'] as List : const [];

    final photoUrls = eventMedia['photoUrls'] is List
        ? (eventMedia['photoUrls'] as List)
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList()
        : <String>[];

    final title = fields['title']?.toString().trim().isNotEmpty == true
        ? fields['title'].toString()
        : data['type']?.toString() ?? 'Submission Details';

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF061E12),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      16,
                      10,
                      12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: primaryGold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submission ID: ${doc.id}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.white12,
                    height: 1,
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(18),
                      children: [
                        _adminDetailSection(
                          title: 'Submission',
                          icon: Icons.assignment_outlined,
                          children: [
                            _adminDetailRow(
                              'Type',
                              data['type'],
                            ),
                            _adminDetailRow(
                              'Status',
                              data['status'],
                            ),
                            _adminDetailRow(
                              'Submitted by',
                              data['submitterEmail'],
                            ),
                            _adminDetailRow(
                              'Owner ID',
                              data['ownerId'],
                            ),
                            _adminDetailRow(
                              'Creator ID',
                              data['creatorId'],
                            ),
                            _adminDetailRow(
                              'Submitted user ID',
                              data['submittedBy'],
                            ),
                            _adminDetailRow(
                              'Created',
                              data['createdAt'],
                            ),
                          ],
                        ),
                        if (fields.isNotEmpty)
                          _adminDetailSection(
                            title: 'Form Information',
                            icon: Icons.description_outlined,
                            children: fields.entries
                                .where(
                                  (entry) =>
                                      entry.value != null &&
                                      entry.value.toString().trim().isNotEmpty,
                                )
                                .map(
                                  (entry) => _adminDetailRow(
                                    _adminReadableFieldName(entry.key),
                                    entry.value,
                                  ),
                                )
                                .toList(),
                          ),
                        if (eventDetails.isNotEmpty)
                          _adminDetailSection(
                            title: 'Event Options',
                            icon: Icons.event_available_outlined,
                            children: [
                              _adminBooleanRow(
                                '18+ only',
                                eventDetails['age18Only'] == true,
                              ),
                              _adminBooleanRow(
                                'Children allowed',
                                eventDetails['kidsAllowed'] == true,
                              ),
                              _adminBooleanRow(
                                'Shisha available',
                                eventDetails['shishaAvailable'] == true,
                              ),
                              _adminBooleanRow(
                                'Alcohol available',
                                eventDetails['alcoholAvailable'] == true,
                              ),
                              _adminBooleanRow(
                                'Food available',
                                eventDetails['foodAvailable'] == true,
                              ),
                              _adminBooleanRow(
                                'Non-refundable',
                                data['nonRefundable'] == true ||
                                    eventDetails['nonRefundable'] == true,
                              ),
                              _adminBooleanRow(
                                'Non-transferable',
                                data['nonTransferable'] == true ||
                                    eventDetails['nonTransferable'] == true,
                              ),
                            ],
                          ),
                        if (artists.isNotEmpty)
                          _adminDetailSection(
                            title: 'Artists / Performers',
                            icon: Icons.mic_external_on_outlined,
                            children: [
                              for (var index = 0;
                                  index < artists.length;
                                  index++)
                                if (artists[index] is Map)
                                  _adminArtistDetail(
                                    Map<String, dynamic>.from(
                                      artists[index] as Map,
                                    ),
                                    index,
                                  ),
                            ],
                          ),
                        if (ticketTypes.isNotEmpty)
                          _adminDetailSection(
                            title: 'Tickets & Prices',
                            icon: Icons.confirmation_number_outlined,
                            children: [
                              for (var index = 0;
                                  index < ticketTypes.length;
                                  index++)
                                if (ticketTypes[index] is Map)
                                  _adminTicketDetail(
                                    Map<String, dynamic>.from(
                                      ticketTypes[index] as Map,
                                    ),
                                    index,
                                  ),
                            ],
                          ),
                        if (photoUrls.isNotEmpty) ...[
                          _adminDetailSection(
                            title: 'Event Photos',
                            icon: Icons.photo_library_outlined,
                            children: [
                              SizedBox(
                                height: 125,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photoUrls.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        photoUrls[index],
                                        width: 150,
                                        height: 125,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return Container(
                                            width: 150,
                                            height: 125,
                                            color: cardGreen,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.white38,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _submissionApproveButton(
                                doc,
                                verificationMode,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _submissionRejectButton(
                                doc,
                                verificationMode,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await _deleteSubmission(doc);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.redAccent,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Delete Permanently',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _adminDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _adminDetailRow(
    String label,
    dynamic value,
  ) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    String displayedValue;

    if (value is Timestamp) {
      final date = value.toDate();
      displayedValue = '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } else {
      displayedValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayedValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminBooleanRow(
    String label,
    bool value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel_outlined,
            color: value ? Colors.greenAccent : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value ? 'Yes' : 'No',
            style: TextStyle(
              color: value ? Colors.greenAccent : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminTicketDetail(
    Map<String, dynamic> ticket,
    int index,
  ) {
    final name = ticket['name']?.toString() ?? 'Ticket ${index + 1}';
    final price = (ticket['price'] as num?)?.toDouble() ?? 0;
    final capacity = (ticket['capacity'] as num?)?.toInt() ?? 0;
    final sold = (ticket['sold'] as num?)?.toInt() ?? 0;
    final active = ticket['active'] != false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryDarkGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            price <= 0 ? 'Free' : '${price.toStringAsFixed(2)} €',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Capacity: $capacity   •   Sold: $sold',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminArtistDetail(
    Map<String, dynamic> artist,
    int index,
  ) {
    final name = artist['name']?.toString().trim().isNotEmpty == true
        ? artist['name'].toString()
        : 'Artist ${index + 1}';

    final photoUrl = artist['photoUrl']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryDarkGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 55,
                  height: 55,
                  child: Icon(
                    Icons.person,
                    color: Colors.white38,
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              width: 55,
              height: 55,
              child: Icon(
                Icons.person,
                color: Colors.white38,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _adminReadableFieldName(String key) {
    const labels = <String, String>{
      'title': 'Title',
      'description': 'Description',
      'country': 'Country',
      'cityAddress': 'Address',
      'phone': 'Phone',
      'email': 'Email',
      'website': 'Website',
      'date': 'Date',
      'startDate': 'Start date',
      'endDate': 'End date',
      'time': 'Start time',
      'startTime': 'Start time',
      'endTime': 'End time',
      'performerDj': 'Artists / Performers',
      'category': 'Category',
      'organizer': 'Organizer',
      'organizerName': 'Organizer',
      'showExactAddress': 'Show exact address',
    };

    if (labels.containsKey(key)) {
      return labels[key]!;
    }

    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    if (spaced.isEmpty) return key;

    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  Widget _submissionApproveButton(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool verificationMode,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
      ),
      onPressed: () => _reviewSubmission(
        doc,
        approved: true,
        verificationMode: verificationMode,
      ),
      icon: Icon(
        Icons.check_circle,
        color: primaryDarkGreen,
      ),
      label: Text(
        'Approve',
        style: TextStyle(
          color: primaryDarkGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _submissionRejectButton(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool verificationMode,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
      onPressed: () => _reviewSubmission(
        doc,
        approved: false,
        verificationMode: verificationMode,
      ),
      icon: const Icon(
        Icons.cancel,
        color: Colors.white,
      ),
      label: const Text(
        'Reject',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _canManageSubmission(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (AppSession.isSuperAdmin) {
      return true;
    }

    final collection = doc.reference.parent.id;
    final roles = AppSession.roles.toSet();

    switch (collection) {
      case 'eventSubmissions':
        return roles.contains('manage_events') ||
            roles.contains('review_events');

      case 'businessSubmissions':
        return roles.contains('manage_businesses') ||
            roles.contains('review_businesses');

      case 'jobSubmissions':
        final data = doc.data() ?? {};
        final submissionType =
            data['type']?.toString().trim().toLowerCase() ?? '';

        if (submissionType == 'professional') {
          return roles.contains('manage_professionals') ||
              roles.contains('review_professionals') ||
              roles.contains('manage_jobs') ||
              roles.contains('review_jobs');
        }

        return roles.contains('manage_jobs') || roles.contains('review_jobs');

      case 'marketplaceSubmissions':
        return roles.contains('manage_marketplace') ||
            roles.contains('review_marketplace');

      case 'professionalSubmissions':
        return roles.contains('manage_professionals') ||
            roles.contains('review_professionals');

      case 'communitySubmissions':
        return roles.contains('manage_habesha_connect_category') ||
            roles.contains('review_habesha_connect_requests');

      default:
        return false;
    }
  }

  Future<void> _reviewSubmission(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool approved,
    required bool verificationMode,
  }) async {
    if (!_canManageSubmission(doc)) {
      _showMessage(
        'Vous n’avez pas la permission de gérer cette catégorie.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }
    final reviewer = _auth.currentUser;

    if (reviewer == null) {
      _showMessage(
        'Session administrateur introuvable.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final data = doc.data() ?? {};
    final status = approved ? 'approved' : 'rejected';

    try {
      await doc.reference.update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewer.uid,
        'reviewedByEmail': reviewer.email ?? AppSession.email,
      });

      if (approved) {
        await _publishApprovedSubmission(
          doc,
          data,
          verificationMode: verificationMode,
        );
      }

      if (approved && verificationMode && data['submittedBy'] != null) {
        final badge = Map<String, dynamic>.from(
          data['verificationBadge'] ?? {},
        );

        await _firestore
            .collection('users')
            .doc(data['submittedBy'].toString())
            .set(
          {
            'verificationStatus': 'approved',
            'verificationBadge': badge.isNotEmpty
                ? badge
                : {
                    'title': data['tierTitle'],
                    'price': data['tierPrice'],
                    'productId': data['tierId'],
                  },
            'verifiedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      _showMessage(
        approved ? 'Submission approved.' : 'Submission rejected.',
        backgroundColor: approved ? cardGreen : Colors.orange,
      );
    } catch (error) {
      _showMessage(
        'Erreur : $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _deleteSubmission(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!_canManageSubmission(doc)) {
      _showMessage(
        'Vous n’avez pas la permission de supprimer cette demande.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text(
          'Delete submission?',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This removes the submission and hides any published feed/category copy.',
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final sourceCollection = doc.reference.parent.id;

      final categoryCollection = switch (sourceCollection) {
        'jobSubmissions' => 'jobs',
        'businessSubmissions' => 'businesses',
        'eventSubmissions' => 'events',
        'communitySubmissions' => 'communities',
        'marketplaceSubmissions' => 'marketplace',
        'verificationRequests' => 'verifications',
        _ => null,
      };

      await doc.reference.delete();

      await _firestore
          .collection('publicFeed')
          .doc('${sourceCollection}_${doc.id}')
          .set(
        {
          'status': 'deleted',
          'deletedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (categoryCollection != null) {
        await _firestore.collection(categoryCollection).doc(doc.id).set(
          {
            'status': 'deleted',
            'deletedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      _showMessage(
        'Submission deleted.',
        backgroundColor: cardGreen,
      );
    } catch (error) {
      _showMessage(
        'Erreur : $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _publishApprovedSubmission(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data, {
    required bool verificationMode,
  }) async {
    final fields = Map<String, dynamic>.from(
      data['fields'] ?? {},
    );

    final badge = Map<String, dynamic>.from(
      data['verificationBadge'] ?? {},
    );

    final sourceCollection = doc.reference.parent.id;

    final title = fields['title']?.toString().trim().isNotEmpty == true
        ? fields['title'].toString()
        : data['tierTitle']?.toString() ??
            data['type']?.toString() ??
            'Approved submission';

    final category = switch (sourceCollection) {
      'jobSubmissions' => 'job',
      'businessSubmissions' => 'business',
      'eventSubmissions' => 'event',
      'communitySubmissions' => 'community',
      'verificationRequests' => 'verification',
      _ => data['type']?.toString() ?? 'approved',
    };
    final imageUrl = (fields['logoUrl'] ??
            fields['businessLogoUrl'] ??
            fields['imageUrl'] ??
            fields['photoUrl'] ??
            fields['coverImageUrl'] ??
            data['logoUrl'] ??
            data['businessLogoUrl'] ??
            data['imageUrl'] ??
            data['photoUrl'] ??
            data['coverImageUrl'] ??
            '')
        .toString()
        .trim();
    await _firestore
        .collection('publicFeed')
        .doc('${sourceCollection}_${doc.id}')
        .set(
      {
        'sourceCollection': sourceCollection,
        'sourceId': doc.id,
        'status': 'published',
        'category': category,
        'communityCategory': fields['communityCategory'],
        'title': title,
        'subtitle': fields['cityAddress']?.toString() ??
            fields['country']?.toString() ??
            data['submitterEmail']?.toString() ??
            '',
        'description': fields['description']?.toString() ??
            fields['requirements']?.toString() ??
            '',
        'imageUrl': imageUrl,
        'logoUrl': imageUrl,
        'submittedBy': data['submittedBy'],
        'submitterEmail': data['submitterEmail'],
        'verificationBadge': badge.isNotEmpty
            ? badge
            : verificationMode
                ? {
                    'title': data['tierTitle'],
                    'price': data['tierPrice'],
                    'productId': data['tierId'],
                  }
                : null,
        'isDemo': false,
        'rating': _parseRating(
          fields['rating']?.toString(),
        ),
        'reviewCount': _parseReviewCount(
          fields['rating']?.toString(),
        ),
        'publishedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
      },
      SetOptions(merge: true),
    );

    final categoryCollection = switch (sourceCollection) {
      'jobSubmissions' => 'jobs',
      'businessSubmissions' => 'businesses',
      'eventSubmissions' => 'events',
      'communitySubmissions' => 'communities',
      'marketplaceSubmissions' => 'marketplace',
      'verificationRequests' => 'verifications',
      _ => null,
    };

    if (categoryCollection != null) {
      final phone = fields['phoneNumber']?.toString() ?? '';

      final location = fields['cityAddress']?.toString() ??
          fields['country']?.toString() ??
          'Europe';

      final address = fields['address']?.toString() ?? location;

      final email = fields['emailAddress']?.toString() ??
          fields['email']?.toString() ??
          data['submitterEmail']?.toString() ??
          '';

      final website = fields['websiteUrl']?.toString() ??
          fields['website']?.toString() ??
          '';

      final whatsapp = phone.isNotEmpty
          ? 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}'
          : '';

      final description = fields['description']?.toString() ??
          fields['requirements']?.toString() ??
          '';

      final publishedCategory = sourceCollection == 'marketplaceSubmissions'
          ? (fields['itemCategory']?.toString().trim().isNotEmpty == true
              ? fields['itemCategory'].toString().trim()
              : 'Habesha & Traditional')
          : fields['businessCategory']?.toString().trim().isNotEmpty == true
              ? fields['businessCategory'].toString().trim()
              : fields['jobCategory']?.toString().trim().isNotEmpty == true
                  ? fields['jobCategory'].toString().trim()
                  : category;

      await _firestore.collection(categoryCollection).doc(doc.id).set(
        {
          ...data,
          ...fields,
          'id': doc.id,
          'name': title,
          'title': title,
          'location': location,
          'address': address,
          'phone': phone.startsWith('tel:') ? phone : 'tel:$phone',
          'email': email,
          'website': website,
          'whatsapp': whatsapp,
          'description': description,
          'businessCategory': publishedCategory,
          'category': publishedCategory,
          'logoUrl': imageUrl,
          'imageUrl': imageUrl,
          'registration': fields['registration']?.toString() ??
              fields['siret']?.toString() ??
              'SIRET: Registered Business',
          'openingHours':
              fields['openingHours']?.toString() ?? 'Mon - Sun: Open',
          'badge': badge['title']?.toString() ??
              (verificationMode ? data['tierTitle']?.toString() : 'Verified'),
          'gallery': data['gallery'] ??
              fields['gallery'] ??
              (imageUrl.isNotEmpty ? [imageUrl] : <String>[]),
          'rating': '5.0 (New)',
          'reviewCount': 0,
          'status': 'published',
          'sourceCollection': sourceCollection,
          'sourceId': doc.id,
          'publishedAt': FieldValue.serverTimestamp(),
          'approvedBy': _auth.currentUser?.uid,
        },
        SetOptions(merge: true),
      );
    }
  }

  double _parseRating(String? ratingText) {
    if (ratingText == null) return 0;

    final match = RegExp(
      r'(\d+(?:\.\d+)?)',
    ).firstMatch(ratingText);

    return double.tryParse(
          match?.group(1) ?? '',
        ) ??
        0;
  }

  int _parseReviewCount(String? ratingText) {
    if (ratingText == null) return 0;

    final match = RegExp(
      r'\((\d+)',
    ).firstMatch(ratingText);

    return int.tryParse(
          match?.group(1) ?? '',
        ) ??
        0;
  }

  // ===========================================================================
  // INVITE ADMIN SCREEN WIDGET
  // ===========================================================================

  Widget _buildInviteAdminForm() {
    if (!AppSession.isSuperAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Seul le Super Admin peut gérer les administrateurs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestion des administrateurs',
            style: TextStyle(
              color: primaryGold,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Le Super Admin attribue un administrateur à une catégorie précise. Un seul administrateur actif peut être associé à une catégorie.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Nouvel administrateur'),
          _buildField(
            'E-mail du compte *',
            'admin@example.com',
            _inviteEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),
          _buildDropdown(
            label: 'Rôle',
            value: selectedInviteRole,
            items: inviteRoles,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedInviteRole = value;

                switch (value) {
                  case 'Jobs Admin':
                    selectedInviteScope = 'Jobs & Employment';
                    break;
                  case 'Businesses Admin':
                    selectedInviteScope = 'Businesses & Services';
                    break;
                  case 'Marketplace Admin':
                    selectedInviteScope = 'Marketplace';
                    break;
                  case 'Events Admin':
                    selectedInviteScope = 'Events';
                    break;
                  case 'Professionals Admin':
                    selectedInviteScope = 'Professionals';
                    break;
                }
              });
            },
          ),
          const SizedBox(height: 15),
          _buildDropdown(
            label: 'Catégorie / Scope *',
            value: selectedInviteScope,
            items: availableScopes,
            onChanged: (value) {
              if (value == null) return;

              if (selectedInviteRole != 'Habesha Connect Admin') {
                return;
              }

              setState(() {
                selectedInviteScope = value;
              });
            },
          ),
          const SizedBox(height: 15),
          _buildField(
            'Code d’accès *',
            'Exemple : 7124',
            _accessCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: primaryGold.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.security,
                  color: primaryGold,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'L’administrateur sera limité à la catégorie sélectionnée. Les permissions sont enregistrées automatiquement dans adminInvites.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              minimumSize: const Size(
                double.infinity,
                52,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _sendAdminInvite,
            icon: Icon(
              Icons.person_add_alt_1,
              color: primaryDarkGreen,
            ),
            label: Text(
              'Créer l’administrateur',
              style: TextStyle(
                color: primaryDarkGreen,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _buildActiveAdmins(),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUICK POST FORM & SUBMISSION HANDLING
  // ===========================================================================

  Future<void> _pickLogoImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _businessLogo = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitAdminListing() async {
    if (_titleController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      _showMessage(
        'Please fill in required fields!',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Administrateur non connecté.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    try {
      String? logoUrl;

      if (_businessLogo != null) {
        final path =
            'listings/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${_businessLogo!.path.split(Platform.pathSeparator).last}';

        final ref = FirebaseStorage.instance.ref(path);

        await ref.putFile(_businessLogo!);

        logoUrl = await ref.getDownloadURL();
      }

      final collection = switch (selectedCategory) {
        'Job Listing' => 'jobs',
        'Community Event' => 'events',
        _ => 'businesses',
      };

      final title = _titleController.text.trim();
      final city = _cityController.text.trim();
      final phone = _phoneController.text.trim();

      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : user.email ?? '';

      final website = _websiteController.text.trim();
      final mapLink = _mapLinkController.text.trim();
      final description = _descController.text.trim();

      final newDoc = await _firestore.collection(collection).add({
        'title': title,
        'name': title,
        'location': city,
        'address': city,
        'phone': phone.startsWith('tel:') ? phone : 'tel:$phone',
        'email': email,
        'website': website,
        'whatsapp': phone.isNotEmpty
            ? 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}'
            : '',
        'mapLink': mapLink,
        'description': description,
        'logoUrl': logoUrl,
        'gallery': logoUrl != null ? [logoUrl] : [],
        'category': selectedCategory,
        'businessCategory': selectedCategory,
        'badge': 'Premium',
        'registration': 'SIRET: Verified Business',
        'openingHours': 'Mon - Sun: Open',
        'status': 'published',
        'isDemo': false,
        'ownerId': user.uid,
        'rating': '5.0 (New)',
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'publishedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('publicFeed')
          .doc('${collection}_${newDoc.id}')
          .set({
        'sourceCollection': collection,
        'sourceId': newDoc.id,
        'status': 'published',
        'category': collection == 'businesses'
            ? 'business'
            : collection == 'jobs'
                ? 'job'
                : 'event',
        'title': title,
        'subtitle': city,
        'description': description,
        'imageUrl': logoUrl ?? '',
        'logoUrl': logoUrl ?? '',
        'phone': phone,
        'submitterEmail': email,
        'verificationBadge': {
          'title': 'Premium',
          'price': 'Verified',
        },
        'isDemo': false,
        'rating': 5.0,
        'reviewCount': 0,
        'publishedAt': FieldValue.serverTimestamp(),
        'approvedBy': user.uid,
      });

      _showMessage(
        '$selectedCategory published successfully.',
        backgroundColor: cardGreen,
      );

      _clearQuickPostForm();
    } catch (error) {
      _showMessage(
        'Listing publish failed: $error',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  void _clearQuickPostForm() {
    _titleController.clear();
    _cityController.clear();
    _phoneController.text = '$phonePrefix ';
    _emailController.clear();
    _websiteController.clear();
    _mapLinkController.clear();
    _descController.clear();

    if (!mounted) return;

    setState(() {
      _businessLogo = null;
    });
  }

  Widget _buildAdminPostForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Official Post / Business Listing',
            style: TextStyle(
              color: primaryGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Business Logo / Profile Picture',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _pickLogoImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cardGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryGold,
                    width: 2,
                  ),
                  image: _businessLogo != null
                      ? DecorationImage(
                          image: FileImage(_businessLogo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _businessLogo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: primaryGold,
                            size: 30,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add Logo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            label: 'Select Category',
            value: selectedCategory,
            items: categories,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 15),
          _buildField(
            'Title / Business Name *',
            'e.g., Habesha Grocery Lyon',
            _titleController,
          ),
          const SizedBox(height: 15),
          _buildDropdown(
            label: 'Country',
            value: selectedCountry,
            items: countryPhoneCodes.keys.toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedCountry = value;
                phonePrefix = countryPhoneCodes[selectedCountry]!;
                _phoneController.text = '$phonePrefix ';
              });
            },
          ),
          const SizedBox(height: 15),
          _buildField(
            'City & Exact Address *',
            'e.g., 12 Rue de Lyon, Lyon',
            _cityController,
          ),
          const SizedBox(height: 15),
          Text(
            'Phone Number *',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: '6 12 34 56 78',
              hintStyle: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildField(
            'Email Address',
            'e.g., info@eurohabesha.eu',
            _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),
          _buildField(
            'Website URL',
            'e.g., https://www.eurohabesha.eu',
            _websiteController,
          ),
          const SizedBox(height: 15),
          _buildField(
            'Google Maps Link',
            'Paste Google Maps location link',
            _mapLinkController,
          ),
          const SizedBox(height: 15),
          _buildField(
            'Description & Details',
            'Describe services, menu, or products...',
            _descController,
            maxLines: 4,
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              minimumSize: const Size(
                double.infinity,
                52,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _submitAdminListing,
            child: Text(
              'Publish Listing Instantly',
              style: TextStyle(
                color: primaryDarkGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI HELPER WIDGETS
  // ===========================================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        title,
        style: TextStyle(
          color: primaryGold,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: cardGreen,
              style: const TextStyle(
                color: Colors.white,
              ),
              isExpanded: true,
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            filled: true,
            fillColor: cardGreen,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),
    );
  }
}

// =============================================================================
// REVIEW MODEL DEFINITION
// =============================================================================

class _ReviewCollection {
  final String title;
  final String collectionName;

  const _ReviewCollection(
    this.title,
    this.collectionName,
  );
}
