import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';

class AdvertisementRequestScreen extends StatefulWidget {
  const AdvertisementRequestScreen({super.key});

  @override
  State<AdvertisementRequestScreen> createState() =>
      _AdvertisementRequestScreenState();
}

class _AdvertisementRequestScreenState
    extends State<AdvertisementRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _budgetController = TextEditingController();

  String _advertisementType = 'Business';
  String _duration = '30 days';
  bool _isSubmitting = false;

  static const primaryDarkGreen = Color(0xFF061E12);
  static const primaryGold = Color(0xFFFFD700);
  static const cardGreen = Color(0xFF004D40);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _businessNameController.dispose();
    _contactController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || AppSession.isGuest) {
      _showMessage('Please sign in before requesting advertising.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('advertisementRequests').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'advertisementType': _advertisementType,
        'duration': _duration,
        'contact': _contactController.text.trim(),
        'budget': _budgetController.text.trim(),
        'submittedBy': user.uid,
        'ownerId': user.uid,
        'submitterEmail': user.email ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your advertising request has been sent for admin approval.',
          ),
        ),
      );
    } catch (e) {
      _showMessage('Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'Request Sponsored Advertising',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Promote your business, service, event, or product on Euro Habesha.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Advertisement title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an advertisement title'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _businessNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Business / brand name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your business or brand name'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _advertisementType,
              dropdownColor: cardGreen,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Advertisement type'),
              items: const [
                DropdownMenuItem(
                  value: 'Business',
                  child: Text('Business'),
                ),
                DropdownMenuItem(
                  value: 'Professional',
                  child: Text('Professional'),
                ),
                DropdownMenuItem(
                  value: 'Marketplace',
                  child: Text('Marketplace'),
                ),
                DropdownMenuItem(
                  value: 'Event',
                  child: Text('Event'),
                ),
                DropdownMenuItem(
                  value: 'Service',
                  child: Text('Service'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _advertisementType = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Advertisement description'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Phone / WhatsApp / Email'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a contact method'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _duration,
              dropdownColor: cardGreen,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Requested duration'),
              items: const [
                DropdownMenuItem(
                  value: '7 days',
                  child: Text('7 days'),
                ),
                DropdownMenuItem(
                  value: '30 days',
                  child: Text('30 days'),
                ),
                DropdownMenuItem(
                  value: '60 days',
                  child: Text('60 days'),
                ),
                DropdownMenuItem(
                  value: '90 days',
                  child: Text('90 days'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _duration = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Estimated budget (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRequest,
              icon: const Icon(Icons.send),
              label: Text(
                _isSubmitting ? 'Sending...' : 'Send Advertising Request',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: primaryDarkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
