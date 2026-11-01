import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPersonalProfileScreen extends StatefulWidget {
  const EditPersonalProfileScreen({super.key});

  @override
  State<EditPersonalProfileScreen> createState() => _EditPersonalProfileScreenState();
}

class _EditPersonalProfileScreenState extends State<EditPersonalProfileScreen> {
  static const dark = Color(0xFF061E12);
  static const green = Color(0xFF004D40);
  static const gold = Color(0xFFFFD700);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  bool _showCity = false;
  bool _showPhone = false;
  bool _loading = true;
  bool _saving = false;
  String? _photoUrl;
  Uint8List? _newPhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = doc.data() ?? <String, dynamic>{};
      if (!mounted) return;
      _name.text = (d['displayName'] ?? user.displayName ?? '').toString();
      _nickname.text = (d['username'] ?? '').toString();
      _city.text = (d['city'] ?? '').toString();
      _phone.text = (d['phone'] ?? '').toString();
      _photoUrl = (d['photoUrl'] ?? user.photoURL)?.toString();
      _showCity = d['showCityPublicly'] == true;
      _showPhone = d['showPhonePublicly'] == true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chargement impossible : $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Le client choisit une photo directement depuis son téléphone.
  // Aucune saisie d'URL n'est demandée.
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: green,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: gold),
            title: const Text('Choisir dans la galerie',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: gold),
            title: const Text('Prendre une photo',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source, maxWidth: 900, imageQuality: 80,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _newPhoto = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo indisponible : $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      String? url = _photoUrl;
      if (_newPhoto != null) {
        final ref = FirebaseStorage.instance.ref('profilePhotos/${user.uid}/avatar.jpg');
        await ref.putData(_newPhoto!, SettableMetadata(contentType: 'image/jpeg'));
        url = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _name.text.trim(),
        'username': _nickname.text.trim(),
        'city': _city.text.trim(),
        'phone': _phone.text.trim(),
        'showCityPublicly': _showCity && _city.text.trim().isNotEmpty,
        'showPhonePublicly': _showPhone && _phone.text.trim().isNotEmpty,
        if (url != null && url.isNotEmpty) 'photoUrl': url,
        'profileCreated': true,
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Synchronise le nom et la photo avec Firebase Auth, sans toucher à l'e-mail de connexion.
      await user.updateDisplayName(_name.text.trim());
      if (url != null && url.isNotEmpty) await user.updatePhotoURL(url);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose(); _nickname.dispose(); _city.dispose(); _phone.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    labelStyle: const TextStyle(color: gold), hintStyle: const TextStyle(color: Colors.white38),
    prefixIcon: Icon(icon, color: gold),
    filled: true, fillColor: dark,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gold)),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(backgroundColor: dark, foregroundColor: gold, title: const Text('Modifier mon profil')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: gold)) :
      Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Mon profil personnel', style: TextStyle(color: gold, fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Personnalisez votre profil. Les informations facultatives restent privées par défaut.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 25),
        Center(child: InkWell(onTap: _pickPhoto, borderRadius: BorderRadius.circular(70), child: Stack(children: [
          CircleAvatar(radius: 57, backgroundColor: green,
            backgroundImage: _newPhoto != null ? MemoryImage(_newPhoto!) : (_photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) : null) as ImageProvider?,
            child: _newPhoto == null && (_photoUrl == null || _photoUrl!.isEmpty) ? const Icon(Icons.person, size: 60, color: gold) : null),
          const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 19, backgroundColor: gold, child: Icon(Icons.camera_alt, color: dark, size: 20))),
        ]))),
        const SizedBox(height: 8),
        const Center(child: Text('Ajouter ou modifier ma photo (facultatif)', style: TextStyle(color: Colors.white70))),
        const SizedBox(height: 25),
        TextFormField(controller: _name, style: const TextStyle(color: Colors.white), textCapitalization: TextCapitalization.words,
          decoration: _dec('Nom affiché *', Icons.badge_outlined),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire.' : null),
        const SizedBox(height: 15),
        TextFormField(controller: _nickname, style: const TextStyle(color: Colors.white),
          decoration: _dec('Nom d’utilisateur (facultatif)', Icons.alternate_email, hint: 'Ex. Getafric')),
        const SizedBox(height: 15),
        TextFormField(readOnly: true, initialValue: user?.email ?? '', style: const TextStyle(color: Colors.white70),
          decoration: _dec('E-mail de connexion', Icons.mail_outline)),
        const Padding(padding: EdgeInsets.only(top: 5, bottom: 18), child: Text('Pour modifier votre adresse de connexion, utilisez les paramètres du compte.', style: TextStyle(color: Colors.white54, fontSize: 12))),
        TextFormField(controller: _city, style: const TextStyle(color: Colors.white),
          decoration: _dec('Ville et pays (facultatif)', Icons.location_city, hint: 'Ex. Lyon, France')),
        SwitchListTile.adaptive(value: _showCity, onChanged: (v) => setState(() => _showCity = v),
          activeTrackColor: gold, title: const Text('Afficher ma ville sur mon profil public', style: TextStyle(color: Colors.white, fontSize: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: _phone, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone,
          decoration: _dec('Téléphone (facultatif)', Icons.phone_outlined)),
        SwitchListTile.adaptive(value: _showPhone, onChanged: (v) => setState(() => _showPhone = v),
          activeTrackColor: gold, title: const Text('Afficher mon téléphone sur mon profil public', style: TextStyle(color: Colors.white, fontSize: 14))),
        const SizedBox(height: 18),
        const Text('Ces choix règlent les préférences de visibilité. Les pages publiques devront respecter ces paramètres lors de leur affichage.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 22),
        SizedBox(height: 54, child: ElevatedButton.icon(onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
          label: Text(_saving ? 'Enregistrement…' : 'Enregistrer mon profil'),
          style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: dark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        const SizedBox(height: 25),
      ])),
    );
  }
}
