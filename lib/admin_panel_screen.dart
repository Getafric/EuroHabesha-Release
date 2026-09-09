import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_session.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  late TabController _tabController;

  // በአውሮፓ ውስጥ ሀበሾች የሚኖሩባቸው አጠቃላይ ሀገራት እና የስልክ ኮዶቻቸው
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
  final List<String> categories = ['Business / Restaurant', 'Marketplace Item', 'Job Listing', 'Community Event'];

  // የሎጎ ፎቶ መምረጫ
  File? _businessLogo;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _mapLinkController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _inviteScopeController = TextEditingController();
  String selectedInviteRole = 'Editor';
  final List<String> inviteRoles = ['Editor', 'Poster', 'Moderator', 'Helper', 'Event Admin', 'Community Admin'];

  final List<Map<String, String>> pendingBusinesses = [
    {'title': 'Lalibela Restaurant Lyon', 'city': 'Lyon, France', 'user': 'Dawit M.'},
    {'title': 'Habesha Hair Salon Paris', 'city': 'Paris, France', 'user': 'Sara K.'},
  ];

  final List<Map<String, String>> pendingVerifications = [
    {'name': 'Dr. Selam (General Practitioner)', 'type': 'Medical Diploma PDF', 'user': 'Dr. Selam'},
    {'name': 'Dawit Legal Services', 'type': 'Professional Bar License', 'user': 'Dawit L.'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    selectedCountry = countryPhoneCodes.keys.first;
    phonePrefix = countryPhoneCodes[selectedCountry]!;
    _phoneController.text = '$phonePrefix ';
  }

  Future<void> _pickLogoImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _businessLogo = File(pickedFile.path);
      });
    }
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
    _inviteScopeController.dispose();
    super.dispose();
  }

  Future<void> _sendAdminInvite() async {
    if (!AppSession.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Super Admin access required.')));
      return;
    }

    final email = _inviteEmailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address.')));
      return;
    }

    await FirebaseFirestore.instance.collection('adminInvites').add({
      'email': email,
      'role': selectedInviteRole,
      'scope': _inviteScopeController.text.trim(),
      'status': 'pending',
      'invitedBy': AppSession.email,
      'createdAt': FieldValue.serverTimestamp(),
      'permissions': _permissionsForRole(selectedInviteRole),
    });

    _inviteEmailController.clear();
    _inviteScopeController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$selectedInviteRole invite saved.')));
    }
  }

  List<String> _permissionsForRole(String role) {
    return switch (role) {
      'Editor' => ['review_submissions', 'edit_content'],
      'Poster' => ['create_posts'],
      'Moderator' => ['review_comments', 'hide_content'],
      'Helper' => ['view_dashboard', 'respond_support'],
      'Event Admin' => ['manage_scoped_event', 'scan_tickets'],
      'Community Admin' => ['manage_scoped_community', 'post_scoped_updates'],
      _ => ['view_dashboard'],
    };
  }

  void _submitAdminListing() {
    if (_titleController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields!')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$selectedCategory published successfully with logo!'), backgroundColor: cardGreen),
    );
    _titleController.clear();
    _cityController.clear();
    _phoneController.clear();
    _mapLinkController.clear();
    _descController.clear();
    setState(() {
      _businessLogo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Admin Control Panel', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryGold,
          unselectedLabelColor: Colors.white60,
          indicatorColor: primaryGold,
          tabs: const [
            Tab(text: 'Businesses & Market'),
            Tab(text: 'Verifications & Docs'),
            Tab(text: 'Community Events'),
            Tab(text: 'Direct Admin Post'),
            Tab(text: 'Invite Admin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmissionReviewTab([
            _ReviewCollection('Business Submissions', 'businessSubmissions'),
            _ReviewCollection('Job / Service Submissions', 'jobSubmissions'),
          ]),
          _buildSubmissionReviewTab([
            _ReviewCollection('Verification Requests', 'verificationRequests'),
          ], verificationMode: true),
          _buildSubmissionReviewTab([
            _ReviewCollection('Event Submissions', 'eventSubmissions'),
            _ReviewCollection('Community Submissions', 'communitySubmissions'),
          ]),
          _buildAdminPostForm(),
          _buildInviteAdminForm(),
        ],
      ),
    );
  }

  Widget _buildSubmissionReviewTab(List<_ReviewCollection> collections, {bool verificationMode = false}) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final collection = collections[index];
        return _buildFirestoreReviewSection(collection, verificationMode: verificationMode);
      },
    );
  }

  Widget _buildFirestoreReviewSection(_ReviewCollection reviewCollection, {bool verificationMode = false}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(reviewCollection.collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: CircularProgressIndicator(color: primaryGold),
          ));
        }

        if (snapshot.hasError) {
          return _buildAdminMessage('${reviewCollection.title}: ${snapshot.error}');
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final status = doc.data()['status']?.toString() ?? 'pendingApproval';
          return status == 'pendingApproval' || status == 'pendingAdminReview' || status == 'pendingPaymentAndReview';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reviewCollection.title, style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(12)),
                child: const Text('No pending submissions found.', style: TextStyle(color: Colors.white54)),
              )
            else
              ...docs.map((doc) => _buildSubmissionCard(doc, verificationMode: verificationMode)),
          ],
        );
      },
    );
  }

  Widget _buildSubmissionCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, {bool verificationMode = false}) {
    final data = doc.data();
    final fields = Map<String, dynamic>.from(data['fields'] ?? {});
    final badge = Map<String, dynamic>.from(data['verificationBadge'] ?? {});
    final title = fields['title']?.toString().trim().isNotEmpty == true
        ? fields['title'].toString()
        : data['tierTitle']?.toString() ?? data['type']?.toString() ?? 'Pending Submission';
    final subtitle = [
      if (fields['jobCategory'] != null) 'Category: ${fields['jobCategory']}',
      if (fields['country'] != null) 'Country: ${fields['country']}',
      if (fields['cityAddress'] != null) 'Address: ${fields['cityAddress']}',
      if (data['submitterEmail'] != null) 'Submitted by: ${data['submitterEmail']}',
      if (badge['title'] != null) 'Badge: ${badge['title']} ${badge['price'] ?? ''}',
      if (data['tierTitle'] != null) 'Tier: ${data['tierTitle']} ${data['tierPrice'] ?? ''}',
    ].join('\n');

    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 12)),
            ],
            if (fields['description'] != null) ...[
              const SizedBox(height: 8),
              Text(fields['description'].toString(), style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 13), maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                    onPressed: () => _reviewSubmission(doc, approved: true, verificationMode: verificationMode),
                    icon: Icon(Icons.check_circle, color: primaryDarkGreen),
                    label: Text('Approve', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => _reviewSubmission(doc, approved: false, verificationMode: verificationMode),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                onPressed: () => _deleteSubmission(doc),
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text('Delete Permanently', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewSubmission(DocumentSnapshot<Map<String, dynamic>> doc, {required bool approved, required bool verificationMode}) async {
    final reviewer = FirebaseAuth.instance.currentUser;
    final data = doc.data() ?? {};
    final status = approved ? 'approved' : 'rejected';

    await doc.reference.update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewer?.uid,
      'reviewedByEmail': reviewer?.email ?? AppSession.email,
    });

    if (approved) {
      await _publishApprovedSubmission(doc, data, verificationMode: verificationMode);
    }

    if (approved && verificationMode && data['submittedBy'] != null) {
      final badge = Map<String, dynamic>.from(data['verificationBadge'] ?? {});
      await FirebaseFirestore.instance.collection('users').doc(data['submittedBy'].toString()).set({
        'verificationStatus': 'approved',
        'verificationBadge': badge.isNotEmpty
            ? badge
            : {
                'title': data['tierTitle'],
                'price': data['tierPrice'],
                'productId': data['tierId'],
              },
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Submission approved.' : 'Submission rejected.')),
      );
    }
  }

  Future<void> _deleteSubmission(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text('Delete submission?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text('This removes the submission and hides any published feed/category copy.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final sourceCollection = doc.reference.parent.id;
    final categoryCollection = switch (sourceCollection) {
      'jobSubmissions' => 'jobs',
      'businessSubmissions' => 'businesses',
      'eventSubmissions' => 'events',
      'communitySubmissions' => 'communities',
      'verificationRequests' => 'verifications',
      _ => null,
    };

    await doc.reference.delete();
    await FirebaseFirestore.instance.collection('publicFeed').doc('${sourceCollection}_${doc.id}').set({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (categoryCollection != null) {
      await FirebaseFirestore.instance.collection(categoryCollection).doc(doc.id).set({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission deleted.')));
    }
  }

  Future<void> _publishApprovedSubmission(DocumentSnapshot<Map<String, dynamic>> doc, Map<String, dynamic> data, {required bool verificationMode}) async {
    final fields = Map<String, dynamic>.from(data['fields'] ?? {});
    final badge = Map<String, dynamic>.from(data['verificationBadge'] ?? {});
    final sourceCollection = doc.reference.parent.id;
    final title = fields['title']?.toString().trim().isNotEmpty == true
        ? fields['title'].toString()
        : data['tierTitle']?.toString() ?? data['type']?.toString() ?? 'Approved submission';
    final category = switch (sourceCollection) {
      'jobSubmissions' => 'job',
      'businessSubmissions' => 'business',
      'eventSubmissions' => 'event',
      'communitySubmissions' => 'community',
      'verificationRequests' => 'verification',
      _ => data['type']?.toString() ?? 'approved',
    };

    await FirebaseFirestore.instance.collection('publicFeed').doc('${sourceCollection}_${doc.id}').set({
      'sourceCollection': sourceCollection,
      'sourceId': doc.id,
      'status': 'published',
      'category': category,
      'title': title,
      'subtitle': fields['cityAddress']?.toString() ?? fields['country']?.toString() ?? data['submitterEmail']?.toString() ?? '',
      'description': fields['description']?.toString() ?? fields['requirements']?.toString() ?? '',
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
      'rating': _parseRating(fields['rating']?.toString()),
      'reviewCount': _parseReviewCount(fields['rating']?.toString()),
      'publishedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));

    final categoryCollection = switch (sourceCollection) {
      'jobSubmissions' => 'jobs',
      'businessSubmissions' => 'businesses',
      'eventSubmissions' => 'events',
      'communitySubmissions' => 'communities',
      'verificationRequests' => 'verifications',
      _ => null,
    };

    if (categoryCollection != null) {
      await FirebaseFirestore.instance.collection(categoryCollection).doc(doc.id).set({
        ...data,
        'status': 'published',
        'sourceCollection': sourceCollection,
        'sourceId': doc.id,
        'title': title,
        'category': category,
        'publishedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
    }
  }

  double _parseRating(String? ratingText) {
    if (ratingText == null) return 0;
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(ratingText);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

  int _parseReviewCount(String? ratingText) {
    if (ratingText == null) return 0;
    final match = RegExp(r'\((\d+)').firstMatch(ratingText);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  Widget _buildAdminMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(12)),
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildInviteAdminForm() {
    if (!AppSession.isSuperAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Only the verified Super Admin can invite other admins.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite Admin', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Assign a role and optional scope. Example scope: church_orthodox_lyon or event_2026_paris.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 16),
          _buildField('User Email *', 'newadmin@example.com', _inviteEmailController, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 15),
          Text('Role', style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedInviteRole,
                dropdownColor: cardGreen,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: inviteRoles.map((role) => DropdownMenuItem<String>(value: role, child: Text(role))).toList(),
                onChanged: (value) => setState(() => selectedInviteRole = value!),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildField('Scope ID', 'optional community/event/business ID', _inviteScopeController),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold, minimumSize: const Size(double.infinity, 50)),
            onPressed: _sendAdminInvite,
            icon: Icon(Icons.person_add_alt_1, color: primaryDarkGreen),
            label: Text('Save Admin Invite', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalList(List<Map<String, String>> items, String type) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: items.isEmpty
          ? Center(child: Text('No pending $type items.', style: const TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  color: cardGreen,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(item['title']!, style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Location: ${item['city']}\nSubmitted by: ${item['user']}', style: const TextStyle(color: Colors.white70, height: 1.4)),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30),
                          onPressed: () => setState(() => items.removeAt(index)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 30),
                          onPressed: () => setState(() => items.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildVerificationList(List<Map<String, String>> items) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: items.isEmpty
          ? const Center(child: Text('No pending verification documents.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  color: cardGreen,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(item['name']!, style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Document: ${item['type']}\nUser: ${item['user']}', style: const TextStyle(color: Colors.white70, height: 1.4)),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                      onPressed: () {
                        setState(() => items.removeAt(index));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verified Badge Granted!')));
                      },
                      child: const Text('Verify 🔵', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── አድሚን ሎጎ እና ስልክ ኮድ (Auto Prefix) ያለው የተሟላ ፖስቲንግ ፎርም ──
  Widget _buildAdminPostForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Official Post / Business Listing', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // ── ሎጎ ፎቶ መምረጫ (Logo Upload Area) ──
          Text('Business Logo / Profile Picture', style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 13)),
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
                  border: Border.all(color: primaryGold, width: 2),
                  image: _businessLogo != null ? DecorationImage(image: FileImage(_businessLogo!), fit: BoxFit.cover) : null,
                ),
                child: _businessLogo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: primaryGold, size: 30),
                          const SizedBox(height: 4),
                          const Text('Add Logo', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ምድብ መምረጫ
          Text('Select Category', style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                dropdownColor: cardGreen,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
            ),
          ),
          const SizedBox(height: 15),

          _buildField('Title / Business Name *', 'e.g., Habesha Grocery Lyon', _titleController),
          const SizedBox(height: 15),

          // ── አውሮፓ ሀገራት መምረጫ ──
          Text('Country', style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCountry,
                dropdownColor: cardGreen,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: countryPhoneCodes.keys.map((cnt) => DropdownMenuItem<String>(value: cnt, child: Text(cnt))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCountry = val!;
                    phonePrefix = countryPhoneCodes[selectedCountry]!;
                    _phoneController.text = '$phonePrefix ';
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 15),

          _buildField('City & Exact Address *', 'e.g., 12 Rue de Lyon, Lyon', _cityController),
          const SizedBox(height: 15),

          // ── ስልክ ቁጥር ከሀገር ኮድ (Prefix) ጋር ──
          Text('Phone Number *', style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 5),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '6 12 34 56 78',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),

          _buildField('Email Address', 'e.g., info@eurohabesha.eu', _emailController),
          const SizedBox(height: 15),
          _buildField('Website URL', 'e.g., https://www.eurohabesha.eu', _websiteController),
          const SizedBox(height: 15),
          _buildField('Google Maps Link (Direct URL) *', 'Paste Google Maps location link', _mapLinkController),
          const SizedBox(height: 15),
          _buildField('Description & Details', 'Describe services, menu, or products...', _descController, maxLines: 4),
          const SizedBox(height: 25),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _submitAdminListing,
            child: Text('Publish Listing Instantly', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            filled: true,
            fillColor: cardGreen,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _ReviewCollection {
  final String title;
  final String collectionName;

  const _ReviewCollection(this.title, this.collectionName);
}
