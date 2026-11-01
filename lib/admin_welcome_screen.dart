import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_session.dart';

/// Admin > Bienvenue. Le logo officiel reste celui de login_screen.dart.
class AdminWelcomeScreen extends StatefulWidget {
  const AdminWelcomeScreen({super.key});

  @override
  State<AdminWelcomeScreen> createState() => _AdminWelcomeScreenState();
}

class _AdminWelcomeScreenState extends State<AdminWelcomeScreen> {
  static const dark = Color(0xFF061E12);
  static const green = Color(0xFF004D40);
  static const gold = Color(0xFFFFD700);
  final _settings = FirebaseFirestore.instance.collection('app_settings').doc('welcome');
  final _picker = ImagePicker();
  Uint8List? _previewBytes;
  bool _busy = false;

  Future<void> _choose() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        _message('Image trop volumineuse (maximum 8 Mo).');
        return;
      }
      if (!mounted) return;
      setState(() => _previewBytes = bytes);
    } catch (e) {
      _message('Impossible de sélectionner la photo : $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: green));
  }

  Future<void> _publish() async {
    if (!AppSession.isSuperAdmin || _previewBytes == null || _busy) return;
    setState(() => _busy = true);
    try {
      final ref = FirebaseStorage.instance.ref('welcome/background_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(_previewBytes!, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await _settings.set({
        'enabled': true,
        'imageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _previewBytes = null);
      _message('Photo de bienvenue publiée.');
    } catch (e) {
      _message('Publication impossible : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    if (!AppSession.isSuperAdmin || _busy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer la photo ?'),
        content: const Text('Le fond vert habituel sera affiché. Le logo restera inchangé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await _settings.set({
        'enabled': false,
        'imageUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _previewBytes = null);
      _message('Photo retirée de la page de bienvenue.');
    } catch (e) {
      _message('Suppression impossible : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(child: Text('Réservé au Super Admin', style: TextStyle(color: Colors.white)));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _settings.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final url = (data['imageUrl'] ?? '').toString();
        final enabled = data['enabled'] == true;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Apparence · Page de bienvenue', style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choisissez une photo depuis votre téléphone ou ordinateur. Le logo officiel Euro Habesha ne change pas.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Container(
              height: 230,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: green, border: Border.all(color: gold), borderRadius: BorderRadius.circular(18)),
              child: _previewBytes != null
                  ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                  : enabled && url.isNotEmpty
                      ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: gold, size: 50)))
                      : const Center(child: Icon(Icons.add_photo_alternate, color: gold, size: 58)),
            ),
            const SizedBox(height: 10),
            Text(_previewBytes != null ? 'Nouvelle photo sélectionnée (non publiée)' : enabled && url.isNotEmpty ? 'Photo actuellement publiée' : 'Aucune photo publiée', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _busy ? null : _choose,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choisir / remplacer une photo'),
              style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: dark, padding: const EdgeInsets.all(15)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy || _previewBytes == null ? null : _publish,
              icon: const Icon(Icons.publish),
              label: Text(_busy ? 'Publication en cours...' : 'Publier la photo'),
              style: OutlinedButton.styleFrom(foregroundColor: gold, side: const BorderSide(color: gold), padding: const EdgeInsets.all(15)),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _busy || (!enabled && _previewBytes == null) ? null : _remove,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Retirer la photo publiée'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
            if (_previewBytes != null)
              TextButton(onPressed: _busy ? null : () => setState(() => _previewBytes = null), child: const Text('Annuler la sélection')),
          ],
        );
      },
    );
  }
}
