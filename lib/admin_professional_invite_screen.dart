import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';

class AdminProfessionalInviteScreen extends StatefulWidget {
  const AdminProfessionalInviteScreen({super.key});
  @override
  State<AdminProfessionalInviteScreen> createState() => _AdminProfessionalInviteScreenState();
}

class _AdminProfessionalInviteScreenState extends State<AdminProfessionalInviteScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _description = TextEditingController();
  final _qualifications = TextEditingController();
  final _services = TextEditingController();
  final _pricing = TextEditingController();
  final _businessId = TextEditingController();
  String _category = 'Translator / Interpreter';
  int _step = 0;
  final categories = const ['Translator / Interpreter', 'Catering', 'Photographer / Videographer', 'Professional Service', 'Other'];

  @override
  void dispose() { for (final c in [_name, _email, _phone, _city, _description, _qualifications, _services, _pricing, _businessId]) { c.dispose(); } super.dispose(); }

  Future<void> _send() async {
    if (!AppSession.isSuperAdmin || _name.text.trim().isEmpty || !_email.text.contains('@')) return;
    try {
      await FirebaseFirestore.instance.collection('professionalInvites').add({
        'fullName': _name.text.trim(), 'email': _email.text.trim().toLowerCase(), 'phone': _phone.text.trim(), 'cityAddress': _city.text.trim(),
        'category': _category, 'description': _description.text.trim(), 'qualifications': _qualifications.text.trim(),
        'services': _services.text.trim(), 'pricing': _pricing.text.trim(), 'businessId': _businessId.text.trim(),
        'status': 'pending', 'permissions': ['manage_own_profile', 'manage_own_services', 'receive_customer_messages', 'respond_to_quotes'],
        'invitedBy': AppSession.email, 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _step = 0);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Professional invitation sent.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invitation failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) return const Center(child: Text('Super Admin access required.', style: TextStyle(color: Colors.white70)));
    return Stepper(
      currentStep: _step,
      onStepContinue: () => _step < 2 ? setState(() => _step++) : _send(),
      onStepCancel: () { if (_step > 0) setState(() => _step--); },
      steps: [
        Step(title: const Text('Identity'), isActive: _step >= 0, content: Column(children: [_field('Full name', _name), _field('Email', _email), _field('Phone', _phone), _field('City / address', _city)])),
        Step(title: const Text('Profession'), isActive: _step >= 1, content: Column(children: [DropdownButtonFormField<String>(value: _category, items: categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _category = v ?? _category), decoration: const InputDecoration(labelText: 'Category')), _field('Description', _description, maxLines: 3), _field('Qualifications / documents', _qualifications, maxLines: 3), _field('SIRET / business information', _businessId)])),
        Step(title: const Text('Services & pricing'), isActive: _step >= 2, content: Column(children: [_field('Services (one per line)', _services, maxLines: 4), _field('Pricing methods and amounts', _pricing, maxLines: 4), const Text('The professional can edit these after accepting. Their permissions do not include general admin access.', style: TextStyle(color: Colors.white70))])),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: const Color(0xFF004D40), border: const OutlineInputBorder())));
}
