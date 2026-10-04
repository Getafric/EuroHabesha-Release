import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'professional_profile_sync_service.dart';

class BusinessMenuManagementScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;

  const BusinessMenuManagementScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
  });

  @override
  State<BusinessMenuManagementScreen> createState() =>
      _BusinessMenuManagementScreenState();
}

class _BusinessMenuManagementScreenState
    extends State<BusinessMenuManagementScreen> {
  static const Color darkGreen = Color(0xFF061E12);
  static const Color cardGreen = Color(0xFF0C3022);
  static const Color gold = Color(0xFFFFD700);

  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;

  String _businessName = 'Services / Menu';
  String _category = '';
  List<Map<String, dynamic>> _jobMenuItems = [];

  bool get _usesArray => widget.sourceCollection == 'jobSubmissions';

  bool get _isCatering {
    final value = _category.toLowerCase();
    return value.contains('catering') ||
        value.contains('food seller') ||
        value.contains('restaurant') ||
        value.contains('injera') ||
        value.contains('pâtisserie') ||
        value.contains('pastry');
  }

  DocumentReference<Map<String, dynamic>> get _businessRef =>
      FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final snapshot = await _businessRef.get();
      final data = snapshot.data() ?? <String, dynamic>{};

      final fields = Map<String, dynamic>.from(
        data['fields'] ?? <String, dynamic>{},
      );

      final rawMenu = data['menuItems'];

      final List<Map<String, dynamic>> menu = [];

      if (rawMenu is List) {
        for (int index = 0; index < rawMenu.length; index++) {
          final raw = rawMenu[index];

          if (raw is Map) {
            final item = Map<String, dynamic>.from(raw);

            item['id'] ??= 'legacy_${index}_${item['name'] ?? 'item'}';

            menu.add(item);
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _businessName = fields['title']?.toString().trim().isNotEmpty == true
            ? fields['title'].toString()
            : 'Services / Menu';

        _category = fields['jobCategory']?.toString() ??
            fields['businessCategory']?.toString() ??
            '';

        _jobMenuItems = menu;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger le menu : $error',
          ),
        ),
      );
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final fileName =
        '${widget.businessId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance.ref(
      'menu_items/${user.uid}/$fileName',
    );

    await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
  }

  Future<void> _deleteStorageImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (_) {
      // Une ancienne image ne doit pas empêcher
      // la suppression du produit.
    }
  }

  String _newItemId() {
    return FirebaseFirestore.instance.collection('_ids').doc().id;
  }

  Future<void> _openProductEditor({
    Map<String, dynamic>? existingItem,
  }) async {
    final nameController = TextEditingController(
      text: existingItem?['name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: existingItem?['description']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: existingItem?['price']?.toString() ?? '',
    );

    final portionController = TextEditingController(
      text: existingItem?['portion']?.toString() ?? '',
    );

    final drinkController = TextEditingController(
      text: existingItem?['drinkOption']?.toString() ?? '',
    );

    XFile? selectedImage;

    String currentImageUrl = existingItem?['imageUrl']?.toString() ?? '';

    bool isAvailable = existingItem?['isAvailable'] != false;

    bool isSpicy = existingItem?['isSpicy'] == true;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              decoration: const BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        existingItem == null
                            ? 'Ajouter un produit'
                            : 'Modifier le produit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ajoutez une photo et les informations utiles au client.',
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 22),
                      GestureDetector(
                        onTap: () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 86,
                            maxWidth: 1600,
                          );

                          if (image != null) {
                            setSheetState(() {
                              selectedImage = image;
                            });
                          }
                        },
                        child: Container(
                          height: 190,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: cardGreen,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (selectedImage != null)
                                Image.file(
                                  File(
                                    selectedImage!.path,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              else if (currentImageUrl.isNotEmpty)
                                Image.network(
                                  currentImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      color: gold,
                                      size: 55,
                                    ),
                                  ),
                                )
                              else
                                const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: gold,
                                        size: 42,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Ajouter une photo',
                                        style: TextStyle(
                                          color: gold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    9,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: darkGreen,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _EditorField(
                        controller: nameController,
                        label: 'Nom du produit *',
                        hint: 'Ex. Doro Wot',
                        icon: Icons.restaurant_outlined,
                      ),
                      const SizedBox(height: 13),
                      _EditorField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Décrivez le plat ou le service',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 13),
                      _EditorField(
                        controller: priceController,
                        label: 'Prix (€) *',
                        hint: 'Ex. 18.50',
                        icon: Icons.euro,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      if (_isCatering) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Options du plat',
                          style: TextStyle(
                            color: gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: gold,
                          title: const Text(
                            'Plat épicé',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          subtitle: const Text(
                            'Indique au client que ce plat est épicé',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          value: isSpicy,
                          onChanged: (value) {
                            setSheetState(() {
                              isSpicy = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _EditorField(
                          controller: portionController,
                          label: 'Portion / nombre de personnes',
                          hint: 'Ex. 1 personne, 4 personnes...',
                          icon: Icons.people_outline,
                        ),
                        const SizedBox(height: 13),
                        _EditorField(
                          controller: drinkController,
                          label: 'Boisson / accompagnement',
                          hint: 'Ex. Boisson incluse, Injera...',
                          icon: Icons.local_drink_outlined,
                        ),
                      ],
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: gold,
                        title: const Text(
                          'Disponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isAvailable
                              ? 'Les clients peuvent commander ce produit.'
                              : 'Le produit reste visible mais indisponible.',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        value: isAvailable,
                        onChanged: (value) {
                          setSheetState(() {
                            isAvailable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: darkGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                          onPressed: () {
                            final name = nameController.text.trim();

                            final price = double.tryParse(
                              priceController.text.trim().replaceAll(',', '.'),
                            );

                            if (name.isEmpty || price == null || price < 0) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ajoutez un nom et un prix valide.',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(
                              sheetContext,
                              {
                                'id': existingItem?['id']?.toString() ??
                                    _newItemId(),
                                'name': name,
                                'description':
                                    descriptionController.text.trim(),
                                'price': price,
                                'isAvailable': isAvailable,
                                'isSpicy': isSpicy,
                                'portion': portionController.text.trim(),
                                'drinkOption': drinkController.text.trim(),
                                'oldImageUrl': currentImageUrl,
                                'selectedImage': selectedImage,
                              },
                            );
                          },
                          icon: Icon(
                            existingItem == null
                                ? Icons.add
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            existingItem == null
                                ? 'Ajouter au menu'
                                : 'Enregistrer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    portionController.dispose();
    drinkController.dispose();

    if (result == null) {
      return;
    }

    await _saveProduct(
      product: result,
      existingItem: existingItem,
    );
  }

  Future<void> _saveProduct({
    required Map<String, dynamic> product,
    Map<String, dynamic>? existingItem,
  }) async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final XFile? selectedImage = product.remove('selectedImage') as XFile?;

      final String oldImageUrl =
          product.remove('oldImageUrl')?.toString() ?? '';

      String imageUrl = oldImageUrl;

      if (selectedImage != null) {
        imageUrl = await _uploadImage(selectedImage) ?? '';

        if (oldImageUrl.isNotEmpty && oldImageUrl != imageUrl) {
          await _deleteStorageImage(oldImageUrl);
        }
      }

      final item = <String, dynamic>{
        'id': product['id'],
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'imageUrl': imageUrl,
        'isAvailable': product['isAvailable'],
        'isSpicy': product['isSpicy'],
        'portion': product['portion'],
        'drinkOption': product['drinkOption'],
        'updatedAt': Timestamp.now(),
      };

      if (_usesArray) {
        final updated = _jobMenuItems.map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();

        if (existingItem == null) {
          item['createdAt'] = Timestamp.now();
          updated.add(item);
        } else {
          final existingId = existingItem['id']?.toString();

          int index = updated.indexWhere(
            (element) => element['id']?.toString() == existingId,
          );

          if (index < 0) {
            index = _jobMenuItems.indexOf(existingItem);
          }

          if (index >= 0) {
            item['createdAt'] = existingItem['createdAt'] ?? Timestamp.now();

            updated[index] = item;
          }
        }

        await _businessRef.update({
          'menuItems': updated,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await ProfessionalProfileSyncService.syncPublishedProfile(
          sourceCollection: widget.sourceCollection,
          sourceId: widget.businessId,
        );

        if (mounted) {
          setState(() {
            _jobMenuItems = updated;
          });
        }
      } else {
        final menuCollection = _businessRef.collection('menuItems');

        final itemId = item['id']?.toString().isNotEmpty == true
            ? item['id'].toString()
            : menuCollection.doc().id;

        item['id'] = itemId;

        if (existingItem == null) {
          item['createdAt'] = FieldValue.serverTimestamp();
        }

        await menuCollection.doc(itemId).set(
              item,
              SetOptions(merge: true),
            );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingItem == null
                ? 'Produit ajouté au menu.'
                : 'Produit mis à jour.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’enregistrer : $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(
    Map<String, dynamic> item,
    bool value,
  ) async {
    try {
      if (_usesArray) {
        final updated = _jobMenuItems.map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();

        final itemId = item['id']?.toString();

        final index = updated.indexWhere(
          (element) => element['id']?.toString() == itemId,
        );

        if (index < 0) {
          return;
        }

        updated[index]['isAvailable'] = value;
        updated[index]['updatedAt'] = Timestamp.now();

        await _businessRef.update({
          'menuItems': updated,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _jobMenuItems = updated;
          });
        }
      } else {
        final id = item['id']?.toString();

        if (id == null || id.isEmpty) {
          return;
        }

        await _businessRef.collection('menuItems').doc(id).update({
          'isAvailable': value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de modifier la disponibilité : $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(
    Map<String, dynamic> item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          title: const Text(
            'Supprimer ce produit ?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            item['name']?.toString() ?? 'Ce produit',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (_usesArray) {
        final itemId = item['id']?.toString();

        final updated = _jobMenuItems
            .where(
              (element) => element['id']?.toString() != itemId,
            )
            .map(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();

        await _businessRef.update({
          'menuItems': updated,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _jobMenuItems = updated;
          });
        }
      } else {
        final id = item['id']?.toString();

        if (id != null && id.isNotEmpty) {
          await _businessRef.collection('menuItems').doc(id).delete();
        }
      }

      await _deleteStorageImage(
        item['imageUrl']?.toString() ?? '',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit supprimé.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de supprimer : $error',
          ),
        ),
      );
    }
  }

  Widget _emptyMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        70,
        24,
        20,
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: cardGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color: gold.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: gold,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Votre menu est vide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez vos plats, produits ou services avec photo, description et prix.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Services / Menu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: darkGreen,
        onPressed: _saving ? null : () => _openProductEditor(),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: darkGreen,
                ),
              )
            : const Icon(Icons.add),
        label: const Text(
          'Ajouter un produit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: gold,
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    12,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: gold.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _businessName,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _category,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: _usesArray
                      ? _jobMenuItems.isEmpty
                          ? _emptyMenu()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                100,
                              ),
                              itemCount: _jobMenuItems.length,
                              itemBuilder: (context, index) {
                                final item = _jobMenuItems[index];

                                return _ProductCard(
                                  item: item,
                                  onEdit: () => _openProductEditor(
                                    existingItem: item,
                                  ),
                                  onDelete: () => _deleteProduct(
                                    item,
                                  ),
                                  onAvailabilityChanged: (value) =>
                                      _toggleAvailability(
                                    item,
                                    value,
                                  ),
                                );
                              },
                            )
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream:
                              _businessRef.collection('menuItems').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: gold,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    24,
                                  ),
                                  child: Text(
                                    'Impossible de charger le menu.\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return _emptyMenu();
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                100,
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];

                                final item = <String, dynamic>{
                                  ...doc.data(),
                                  'id': doc.id,
                                };

                                return _ProductCard(
                                  item: item,
                                  onEdit: () => _openProductEditor(
                                    existingItem: item,
                                  ),
                                  onDelete: () => _deleteProduct(
                                    item,
                                  ),
                                  onAvailabilityChanged: (value) =>
                                      _toggleAvailability(
                                    item,
                                    value,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onAvailabilityChanged;

  const _ProductCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    const cardGreen = Color(0xFF0C3022);

    final name = item['name']?.toString() ?? 'Produit';

    final description = item['description']?.toString() ?? '';

    final imageUrl = item['imageUrl']?.toString() ?? '';

    final portion = item['portion']?.toString() ?? '';

    final drink = item['drinkOption']?.toString() ?? '';

    final isAvailable = item['isAvailable'] != false;

    final isSpicy = item['isSpicy'] == true;

    final priceValue = item['price'];

    final double price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(
              priceValue?.toString() ?? '',
            ) ??
            0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _MenuImagePlaceholder(),
              ),
            )
          else
            const SizedBox(
              height: 145,
              child: _MenuImagePlaceholder(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${price.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.35,
                    ),
                  ),
                ],
                if (isSpicy || portion.isNotEmpty || drink.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if (isSpicy)
                        const _OptionChip(
                          icon: Icons.local_fire_department,
                          text: 'Épicé',
                        ),
                      if (portion.isNotEmpty)
                        _OptionChip(
                          icon: Icons.people_outline,
                          text: portion,
                        ),
                      if (drink.isNotEmpty)
                        _OptionChip(
                          icon: Icons.local_drink_outlined,
                          text: drink,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: isAvailable,
                      activeThumbColor: gold,
                      onChanged: onAvailabilityChanged,
                    ),
                    Text(
                      isAvailable ? 'Disponible' : 'Indisponible',
                      style: TextStyle(
                        color: isAvailable ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: gold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuImagePlaceholder extends StatelessWidget {
  const _MenuImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF103A2A),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            color: Color(0xFFFFD700),
            size: 42,
          ),
          SizedBox(height: 7),
          Text(
            'Photo du produit',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OptionChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFFFFD700),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _EditorField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFFFD700),
        ),
        filled: true,
        fillColor: const Color(0xFF0C3022),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFFFD700),
          ),
        ),
      ),
    );
  }
}
