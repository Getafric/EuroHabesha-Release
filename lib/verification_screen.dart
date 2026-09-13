import 'package:file_selector/file_selector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final _businessNameController = TextEditingController();
  final _countryController = TextEditingController(text: 'France');
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  XFile? _selectedDocument;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    const typeGroup = XTypeGroup(
      label: 'Verification documents',
      extensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file != null) {
      setState(() => _selectedDocument = file);
    }
  }

  Future<void> _submitVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before requesting verification.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your business or professional name.')),
      );
      return;
    }

    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach an official registration document, license, or diploma PDF/image.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final bytes = await _selectedDocument!.readAsBytes();
      final safeName = _selectedDocument!.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final storagePath = 'verificationDocs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      await storageRef.putData(bytes);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('verificationRequests').add({
        'submittedBy': user.uid,
        'submitterEmail': user.email,
        'name': _businessNameController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': 'pendingAdminReview',
        'documentName': _selectedDocument!.name,
        'documentStoragePath': storagePath,
        'documentDownloadUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user verification status to pending
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'verificationStatus': 'pending',
        'verificationRequestedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request submitted for Admin review. Thank you!'),
          backgroundColor: cardGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Request Admin Verification', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.verified, color: Color(0xFFFFD700), size: 56),
          const SizedBox(height: 12),
          const Text(
            'Official Identity & Business Verification',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Submit your official business registration (SIRET/SIREN), professional license, or ID document for manual Admin verification. Once verified, your profile will display the clean "✓ Verified" mark.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),

          _buildField('Business or Professional Name *', _businessNameController, hint: 'e.g., Lucy Habesha Restaurant or Dr. Selam'),
          _buildField('Country *', _countryController, hint: 'e.g., France, Germany, Switzerland...'),
          _buildField('City & Address *', _cityController, hint: 'e.g., Lyon, Paris, Geneva...'),
          _buildField('Additional Notes / SIRET info', _notesController, maxLines: 3, hint: 'Provide any extra registration numbers or context for admin review.'),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attach Official Document / Proof *', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                const Text('Upload your SIRET proof, diploma, license, or business registration PDF / image.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryGold),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.upload_file, color: primaryGold),
                  label: Text(
                    _selectedDocument?.name ?? 'Choose Document or Photo',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryDarkGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : _submitVerification,
            icon: const Icon(Icons.send),
            label: Text(
              _isSubmitting ? 'Submitting for Admin Review...' : 'Submit Verification Request',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
