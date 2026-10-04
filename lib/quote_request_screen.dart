import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuoteRequestScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  const QuoteRequestScreen({super.key, required this.provider});
  @override
  State<QuoteRequestScreen> createState() => _QuoteRequestScreenState();
}

class _QuoteRequestScreenState extends State<QuoteRequestScreen> {
  final _service = TextEditingController();
  final _details = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    _service.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _service.text.trim().isEmpty ||
        _details.text.trim().isEmpty) return;
    setState(() => saving = true);
    await FirebaseFirestore.instance.collection('quoteRequests').add({
      'customerId': user.uid,
      'customerEmail': user.email,
      'providerId': widget.provider['ownerId'],
      'providerName': widget.provider['name'],
      'service': _service.text.trim(),
      'details': _details.text.trim(),
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quote request sent.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF061E12),
        appBar: AppBar(
            title: const Text('Request a Quote'),
            backgroundColor: const Color(0xFF061E12)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Request from ${widget.provider['name']}',
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _field('Service needed', _service),
          _field('Describe what you need', _details, maxLines: 6),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: saving ? null : _send,
              child: Text(saving ? 'Sending...' : 'Send Request'))
        ]),
      );
  Widget _field(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
              controller: c,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF004D40),
                  border: const OutlineInputBorder())));
}
