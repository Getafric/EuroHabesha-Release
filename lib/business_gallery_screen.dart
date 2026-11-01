

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
        const SnackBar(content: Text('Vous devez être connecté.')),
      );
      return;
    }

    setState(() => _uploading = true);
    final uploadedReferences = <Reference>[];
    var savedToFirestore = false;

    try {
      if (!['businessSubmissions', 'jobSubmissions']
          .contains(widget.sourceCollection)) {
        throw Exception('Type de profil non autorisé.');
      }

      final business = await _documentReference.get();
      if (!business.exists || business.data()?['ownerId'] != user.uid) {
        throw Exception('Vous n’êtes pas propriétaire de ce profil.');
      }

      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (files.isEmpty) return;

      final newUrls = <String>[];
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        final extension = file.name.split('.').last.toLowerCase();
        final contentTypes = <String, String>{
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'webp': 'image/webp',
        };
        final contentType = contentTypes[extension];
        if (contentType == null) {
          throw Exception('Format non accepté : ${file.name}. Utilisez JPG, PNG ou WebP.');
        }

        final bytes = await file.readAsBytes();
        if (bytes.isEmpty || bytes.length >= 8 * 1024 * 1024) {
          throw Exception('Chaque photo doit faire moins de 8 Mo.');
        }

        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_$index.$extension';
        final reference = FirebaseStorage.instance.ref().child(
          'professional_gallery/'
          '${widget.sourceCollection}/'
          '${widget.businessId}/'
          '${user.uid}/'
          '$fileName',
        );

        await reference.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        );
        uploadedReferences.add(reference);
        newUrls.add(await reference.getDownloadURL());
      }

      await _documentReference.update({
        'gallery': FieldValue.arrayUnion(newUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      savedToFirestore = true;
      await _loadGallery();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newUrls.length == 1
              ? 'Photo ajoutée.'
              : '${newUrls.length} photos ajoutées.'),
        ),
      );
    } catch (e) {
      // Ne pas laisser de nouveaux fichiers isolés si Firestore a échoué.
      if (!savedToFirestore) {
        for (final reference in uploadedReferences) {
          try {
            await reference.delete();
          } catch (_) {
            // Le nettoyage peut échouer si les règles ne sont pas déployées.
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ajouter les photos : $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
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
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté.')),
      );
      return;
    }

    try {
      final business = await _documentReference.get();
      if (!['businessSubmissions', 'jobSubmissions']
              .contains(widget.sourceCollection) ||
          !business.exists ||
          business.data()?['ownerId'] != user.uid) {
        throw Exception('Vous n’êtes pas propriétaire de ce profil.');
      }

      // Suppression atomique de l’URL : aucune autre photo n’est écrasée.
      await _documentReference.update({
        'gallery': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Les anciennes photos restent dans la galerie tant qu'elles ne sont
      // pas explicitement supprimées. Ne supprimer du Storage que nos fichiers.
      var storageDeleted = true;
      try {
        final reference = FirebaseStorage.instance.refFromURL(imageUrl);
        final expectedPrefix =
            'professional_gallery/${widget.sourceCollection}/'
            '${widget.businessId}/${user.uid}/';
        if (reference.fullPath.startsWith(expectedPrefix)) {
          await reference.delete();
        }
      } catch (_) {
        storageDeleted = false;
      }

      await _loadGallery();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(storageDeleted
              ? 'Photo retirée de la galerie.'
              : 'Photo retirée, mais son fichier Storage n’a pas pu être supprimé.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de supprimer la photo : $e')),
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
