import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BusinessGalleryScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;

  const BusinessGalleryScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
  });

  @override
  State<BusinessGalleryScreen> createState() => _BusinessGalleryScreenState();
}

class _BusinessGalleryScreenState extends State<BusinessGalleryScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;

  List<String> _gallery = [];

  DocumentReference<Map<String, dynamic>> get _documentReference =>
      FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId);

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      final snapshot = await _documentReference.get();
      final data = snapshot.data();

      final rawGallery = data?['gallery'];

      final gallery = rawGallery is List
          ? rawGallery
              .map((item) => item.toString())
              .where((url) => url.trim().isNotEmpty)
              .toList()
          : <String>[];

      if (!mounted) return;

      setState(() {
        _gallery = gallery;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger la galerie : $e',
          ),
        ),
      );
    }
  }

  Future<void> _addPhotos() async {
    if (_uploading) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté.'),
        ),
      );
      return;
    }

    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
    });

    try {
      final newUrls = <String>[];

      for (int index = 0; index < files.length; index++) {
        final file = files[index];

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';

        final storageReference = FirebaseStorage.instance.ref().child(
              'professional_gallery/'
              '${user.uid}/'
              '${widget.businessId}/'
              '$fileName',
            );

        await storageReference.putFile(
          File(file.path),
          SettableMetadata(
            contentType: 'image/jpeg',
          ),
        );

        final downloadUrl = await storageReference.getDownloadURL();

        newUrls.add(downloadUrl);
      }

      final updatedGallery = [
        ..._gallery,
        ...newUrls,
      ];

      await _documentReference.update({
        'gallery': updatedGallery,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _gallery = updatedGallery;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newUrls.length == 1
                ? 'Photo ajoutée.'
                : '${newUrls.length} photos ajoutées.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’ajouter les photos : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          title: const Text(
            'Supprimer la photo ?',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Cette photo sera retirée de votre galerie professionnelle.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final updatedGallery = List<String>.from(_gallery)..remove(imageUrl);

      await _documentReference.update({
        'gallery': updatedGallery,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {
        // La référence Firestore est déjà supprimée.
        // Une ancienne URL externe ne doit pas bloquer l'opération.
      }

      if (!mounted) return;

      setState(() {
        _gallery = updatedGallery;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo supprimée.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de supprimer la photo : $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const Text(
          'Photos & Galerie',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _addPhotos,
        backgroundColor: primaryGold,
        foregroundColor: primaryDarkGreen,
        icon: _uploading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryDarkGreen,
                ),
              )
            : const Icon(
                Icons.add_photo_alternate_outlined,
              ),
        label: Text(
          _uploading ? 'Envoi...' : 'Ajouter des photos',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            )
          : _gallery.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: primaryGold,
                          size: 70,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Votre galerie est vide',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ajoutez des photos de votre activité, '
                          'de vos produits ou de vos réalisations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    100,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _gallery.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _gallery[index];

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: cardGreen,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white54,
                                    size: 42,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Supprimer',
                                onPressed: () => _deletePhoto(imageUrl),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
