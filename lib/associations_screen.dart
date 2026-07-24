import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'access_control.dart';
import 'app_localization_helper.dart';
import 'association_profile_page.dart';
import 'community_groups_screen.dart';
import 'registration_screen.dart';

class AssociationsScreen extends StatefulWidget {
  const AssociationsScreen({super.key});

  @override
  State<AssociationsScreen> createState() => _AssociationsScreenState();
}

class _AssociationsScreenState extends State<AssociationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _projectsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Uint8List? _documentBytes;
  Uint8List? _logoBytes;
  Uint8List? _coverBytes;
  String? _documentName;
  bool _isSubmitting = false;

  Future<void> _refreshAssociations() async {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _serialNumberController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    _contactPhoneController.dispose();
    _projectsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required String target, required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
    );

    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      if (target == 'document') {
        _documentBytes = bytes;
        _documentName = picked.name;
      } else if (target == 'logo') {
        _logoBytes = bytes;
      } else if (target == 'cover') {
        _coverBytes = bytes;
      }
    });
  }

  Future<void> _submitAssociation() async {
    if (_isSubmitting) {
      return;
    }
    if (!AccessControl.ensureVerified(context, actionLabel: 'Submit Association Verification')) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_documentBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload or scan the official legal registration document.'),
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please log in again before submitting documents.'),
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final projects = _projectsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    try {
      final associationRef = FirebaseFirestore.instance.collection('associations').doc();
      final uid = firebaseUser.uid;

      final safeDocumentName = (_documentName == null || _documentName!.trim().isEmpty)
          ? 'registration_document.jpg'
          : _documentName!.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

      final documentStoragePath = 'associationDocs/$uid/${associationRef.id}/$safeDocumentName';
      final documentRef = FirebaseStorage.instance.ref().child(documentStoragePath);
      await documentRef.putData(_documentBytes!);
      final documentDownloadUrl = await documentRef.getDownloadURL();

      String logoDownloadUrl = '';
      String logoStoragePath = '';
      if (_logoBytes != null) {
        logoStoragePath = 'profileMedia/$uid/associations/${associationRef.id}/logo.jpg';
        final logoRef = FirebaseStorage.instance.ref().child(logoStoragePath);
        await logoRef.putData(_logoBytes!);
        logoDownloadUrl = await logoRef.getDownloadURL();
      }

      String coverDownloadUrl = '';
      String coverStoragePath = '';
      if (_coverBytes != null) {
        coverStoragePath = 'profileMedia/$uid/associations/${associationRef.id}/cover.jpg';
        final coverRef = FirebaseStorage.instance.ref().child(coverStoragePath);
        await coverRef.putData(_coverBytes!);
        coverDownloadUrl = await coverRef.getDownloadURL();
      }

      await associationRef.set({
        'ownerUid': uid,
        'legalName': _legalNameController.text.trim(),
        'email': _emailController.text.trim(),
        'exactAddress': _addressController.text.trim(),
        'serialRegistrationNumber': _serialNumberController.text.trim(),
        'description': _descriptionController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'links': {
          'website': _websiteController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'tiktok': _tiktokController.text.trim(),
        },
        'activeProjects': projects,
        'rating': 0.0,
        'reviewCount': 0,
        'verificationStatus': 'pending',
        'verifiedTick': false,
        'verificationNotice': 'Your documents have been submitted. We will verify your credentials within 24 hours.',
        'documentName': safeDocumentName,
        'documentStoragePath': documentStoragePath,
        'documentDownloadUrl': documentDownloadUrl,
        'logoStoragePath': logoStoragePath,
        'logoDownloadUrl': logoDownloadUrl,
        'coverStoragePath': coverStoragePath,
        'coverDownloadUrl': coverDownloadUrl,
        // Clear large legacy fields to keep docs lightweight.
        'documentImageBase64': '',
        'logoImageBase64': '',
        'coverImageBase64': '',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
      });

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your documents have been submitted. We will verify your credentials within 24 hours.'),
          backgroundColor: Color(0xFF0B7A55),
        ),
      );

      _legalNameController.clear();
      _emailController.clear();
      _addressController.clear();
      _serialNumberController.clear();
      _descriptionController.clear();
      _websiteController.clear();
      _facebookController.clear();
      _tiktokController.clear();
      _contactPhoneController.clear();
      _projectsController.clear();
      setState(() {
        _documentBytes = null;
        _logoBytes = null;
        _coverBytes = null;
        _documentName = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to submit association: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    }
  }

  Widget _buildImagePickerCard({required String title, required String target, Uint8List? bytes}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(bytes, height: 120, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF061E12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              alignment: Alignment.center,
              child: const Text('No file selected', style: TextStyle(color: Colors.white60)),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(target: target, fromCamera: false),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickImage(target: target, fromCamera: true),
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Scan'),
              ),
            ],
          ),
          if (target == 'document' && _documentName != null) ...[
            const SizedBox(height: 6),
            Text('File: $_documentName', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('associations').orderBy('submittedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No association profiles yet. Submit one using the Registration tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name = (data['legalName'] ?? '').toString();
            final status = (data['verificationStatus'] ?? 'pending').toString();
            final verified = data['verifiedTick'] == true;
            final followerCount = (data['followerCount'] ?? 0) as int;
            final logoUrl = (data['logoDownloadUrl'] ?? '').toString();
            final coverUrl = (data['coverDownloadUrl'] ?? '').toString();
            final logo64 = (data['logoImageBase64'] ?? '').toString();
            final cover64 = (data['coverImageBase64'] ?? '').toString();
            final location = (data['exactAddress'] ?? '').toString();
            Uint8List? logoBytes;
            Uint8List? coverBytes;
            if (logo64.isNotEmpty) {
              try {
                logoBytes = base64Decode(logo64);
              } catch (_) {}
            }
            if (cover64.isNotEmpty) {
              try {
                coverBytes = base64Decode(cover64);
              } catch (_) {}
            }

            final ImageProvider<Object>? logoImage = logoUrl.isNotEmpty
              ? NetworkImage(logoUrl) as ImageProvider<Object>
              : (logoBytes == null ? null : MemoryImage(logoBytes) as ImageProvider<Object>);
            final ImageProvider<Object>? coverImage = coverUrl.isNotEmpty
              ? NetworkImage(coverUrl) as ImageProvider<Object>
              : (coverBytes == null ? null : MemoryImage(coverBytes) as ImageProvider<Object>);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AssociationProfilePage(
                      associationId: docs[index].id,
                      data: data,
                    ),
                  ),
                );
              },
              child: Card(
                color: const Color(0xFF0E2E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.white10),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        color: const Color(0xFF133626),
                        image: coverImage == null
                            ? null
                            : DecorationImage(
                                image: coverImage,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF061E12),
                            backgroundImage: logoImage,
                            child: logoImage == null ? const Icon(Icons.apartment, color: Colors.white70) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name.isEmpty ? 'Unnamed Association' : name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    if (verified)
                                      const Icon(
                                        Icons.verified,
                                        color: Color(0xFF2196F3),
                                        size: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(location, style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: status == 'verified' ? const Color(0xFF0B7A55) : const Color(0xFF7A5A0B),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status == 'verified' ? 'Verified' : 'Pending Verification',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$followerCount followers',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF061E12),
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Associations'),
          actions: [AppLocalizationHelper.languageMenu(context)],
          bottom: const TabBar(
            indicatorColor: Color(0xFFF59E0B),
            tabs: [
              Tab(icon: Icon(Icons.verified_user_outlined), text: 'Registration & Verification'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Profiles'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _refreshAssociations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E2E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Association Verification Registration',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload legal documents during registration. Your profile is created instantly but remains Pending until admin review.',
                              style: TextStyle(color: Colors.white70, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your documents have been submitted. We will verify your credentials within 24 hours.',
                              style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFF59E0B)),
                                foregroundColor: const Color(0xFFF59E0B),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                                );
                              },
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Create User Account (If Needed)'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _legalNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Legal Name'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Legal Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Email'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Email is required';
                          if (!value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: _inputDecoration('Exact Physical Address'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Exact address is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _serialNumberController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Serial Registration Number'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Serial registration number is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Description of Goals / Mission'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactPhoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Contact Phone'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _websiteController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Website URL'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _facebookController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Facebook URL'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tiktokController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('TikTok URL'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _projectsController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: _inputDecoration('Active Projects / Posts (one item per line)'),
                      ),
                      const SizedBox(height: 12),
                      _buildImagePickerCard(
                        title: 'Official Legal Registration Document (Required)',
                        target: 'document',
                        bytes: _documentBytes,
                      ),
                      const SizedBox(height: 12),
                      _buildImagePickerCard(
                        title: 'Profile Picture / Logo (Optional)',
                        target: 'logo',
                        bytes: _logoBytes,
                      ),
                      const SizedBox(height: 12),
                      _buildImagePickerCard(
                        title: 'Cover / Background Photo (Optional)',
                        target: 'cover',
                        bytes: _coverBytes,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: const Color(0xFF061E12),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isSubmitting ? null : _submitAssociation,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061E12)),
                                ),
                              )
                            : const Text('Submit Association for Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CommunityGroupsScreen()),
                          );
                        },
                        icon: const Icon(Icons.groups_2_outlined),
                        label: const Text('Open Group Chat / Community'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _refreshAssociations,
              child: _buildProfilesTab(),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF0E2E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }
}
