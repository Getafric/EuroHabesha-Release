import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';
import 'status_badge_widget.dart';

class AdminUniversalContentManagerScreen extends StatefulWidget {
  const AdminUniversalContentManagerScreen({super.key});

  @override
  State<AdminUniversalContentManagerScreen> createState() => _AdminUniversalContentManagerScreenState();
}

class _AdminUniversalContentManagerScreenState extends State<AdminUniversalContentManagerScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  String _selectedSection = 'businesses';

  final List<Map<String, String>> _sections = [
    {'key': 'businesses', 'label': 'Businesses & Restaurants'},
    {'key': 'jobs', 'label': 'Jobs & Professionals'},
    {'key': 'events', 'label': 'Events'},
    {'key': 'communities', 'label': 'Communities & Spiritual'},
    {'key': 'marketplace', 'label': 'Marketplace Items'},
    {'key': 'posts', 'label': 'Community Feed Posts'},
  ];

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(
        child: Text('Super Admin access required.', style: TextStyle(color: Colors.white70)),
      );
    }

    return Column(
      children: [
        // Horizontal category switcher
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final sec = _sections[index];
              final isSel = _selectedSection == sec['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(sec['label']!),
                  selected: isSel,
                  selectedColor: primaryGold,
                  backgroundColor: cardGreen,
                  labelStyle: TextStyle(
                    color: isSel ? primaryDarkGreen : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSection = sec['key']!);
                  },
                ),
              );
            },
          ),
        ),
        // Add manual content button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Managing: ${_sections.firstWhere((s) => s['key'] == _selectedSection)['label']}',
                style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  foregroundColor: primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                onPressed: () => _showAddEditDialog(null),
              ),
            ],
          ),
        ),
        // Live items stream
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection(_selectedSection).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryGold));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No items in this category yet.\nTap "+ Add Content" to create one.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, height: 1.4),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = data['title']?.toString() ?? data['name']?.toString() ?? data['text']?.toString() ?? 'Item';
                  final subtitle = data['location']?.toString() ?? data['address']?.toString() ?? data['category']?.toString() ?? data['type']?.toString() ?? '';
                  final status = data['status']?.toString() ?? 'published';
                  final isVerified = data['isVerified'] == true || data['verificationStatus'] == 'approved';
                  final subTier = data['subscriptionTier']?.toString();
                  final imgUrl = data['imageUrl']?.toString() ?? data['image']?.toString() ?? data['logoUrl']?.toString();

                  return Card(
                    color: cardGreen,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imgUrl != null && imgUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imgUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      width: 50,
                                      height: 50,
                                      color: primaryDarkGreen,
                                      child: Icon(Icons.image, color: primaryGold, size: 24),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: primaryGold.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.article_outlined, color: primaryGold, size: 24),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: status == 'published' || status == 'approved'
                                                ? Colors.greenAccent.withOpacity(0.2)
                                                : Colors.redAccent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: status == 'published' || status == 'approved' ? Colors.greenAccent : Colors.redAccent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        StatusBadgeWidget(isVerified: isVerified, subscriptionTier: subTier, compact: true),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGold,
                                  foregroundColor: primaryDarkGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _showAddEditDialog(doc),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Edit / Replace Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              if (_selectedSection == 'businesses' || _selectedSection == 'jobs')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isVerified ? Colors.grey.shade700 : const Color(0xFF00E676),
                                    foregroundColor: isVerified ? Colors.white : const Color(0xFF061E12),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () => _toggleVerify(doc, isVerified),
                                  icon: Icon(isVerified ? Icons.close : Icons.verified, size: 14),
                                  label: Text(isVerified ? 'Unverify' : 'Verify ✓', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _delete(doc),
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
                                label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddEditDialog(DocumentSnapshot<Map<String, dynamic>>? existingDoc) {
    final isEditing = existingDoc != null;
    final data = existingDoc?.data() ?? {};

    final titleController = TextEditingController(text: data['title']?.toString() ?? data['name']?.toString() ?? data['text']?.toString() ?? '');
    final locationController = TextEditingController(text: data['location']?.toString() ?? data['address']?.toString() ?? '');
    final descController = TextEditingController(text: data['description']?.toString() ?? data['text']?.toString() ?? '');
    final phoneController = TextEditingController(text: data['phone']?.toString() ?? '');
    final imageController = TextEditingController(text: data['imageUrl']?.toString() ?? data['image']?.toString() ?? data['logoUrl']?.toString() ?? '');
    final categoryController = TextEditingController(text: data['category']?.toString() ?? data['type']?.toString() ?? data['businessCategory']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cardGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing ? 'Edit Content' : 'Add New Content',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('Title / Name *', titleController),
              _dialogField('Category / Type', categoryController, hint: 'e.g. Restaurants, Orthodox Church, Concert...'),
              _dialogField('Location / City / Address', locationController),
              _dialogField('Phone Number', phoneController),
              _dialogField('Image / Photo URL', imageController, hint: 'Paste image link or upload'),
              _dialogField('Description / Details', descController, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final updateData = {
                'title': title,
                'name': title,
                'category': categoryController.text.trim(),
                'type': categoryController.text.trim(),
                'businessCategory': categoryController.text.trim(),
                'location': locationController.text.trim(),
                'address': locationController.text.trim(),
                'phone': phoneController.text.trim(),
                'imageUrl': imageController.text.trim(),
                'image': imageController.text.trim(),
                'description': descController.text.trim(),
                'status': 'published',
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (isEditing) {
                await existingDoc.reference.set(updateData, SetOptions(merge: true));
              } else {
                updateData['createdAt'] = FieldValue.serverTimestamp();
                updateData['publishedAt'] = FieldValue.serverTimestamp();
                updateData['isDemo'] = false;
                await FirebaseFirestore.instance.collection(_selectedSection).add(updateData);
              }

              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEditing ? 'Content updated successfully.' : 'New content published.'),
                  backgroundColor: cardGreen,
                ));
              }
            },
            child: Text(
              isEditing ? 'Save Changes' : 'Publish',
              style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          filled: true,
          fillColor: primaryDarkGreen,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Future<void> _toggleVerify(DocumentSnapshot<Map<String, dynamic>> doc, bool current) async {
    final next = !current;
    await doc.reference.update({
      'isVerified': next,
      'verificationStatus': next ? 'approved' : 'unverified',
      'verifiedAt': next ? FieldValue.serverTimestamp() : null,
      'verifiedBy': AppSession.email,
    });
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text('Delete Content?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete this item from the database.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await doc.reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted.')));
      }
    }
  }
}
