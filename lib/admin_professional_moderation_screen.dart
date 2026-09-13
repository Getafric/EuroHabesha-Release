import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';
import 'status_badge_widget.dart';

class AdminProfessionalModerationScreen extends StatefulWidget {
  const AdminProfessionalModerationScreen({super.key});

  @override
  State<AdminProfessionalModerationScreen> createState() => _AdminProfessionalModerationScreenState();
}

class _AdminProfessionalModerationScreenState extends State<AdminProfessionalModerationScreen> {
  String _selectedCollection = 'businesses';

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(child: Text('Super Admin access required.', style: TextStyle(color: Colors.white70)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Businesses & Restaurants'),
                selected: _selectedCollection == 'businesses',
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF004D40),
                labelStyle: TextStyle(
                  color: _selectedCollection == 'businesses' ? const Color(0xFF061E12) : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCollection = 'businesses');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Jobs & Professionals'),
                selected: _selectedCollection == 'jobs',
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF004D40),
                labelStyle: TextStyle(
                  color: _selectedCollection == 'jobs' ? const Color(0xFF061E12) : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCollection = 'jobs');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection(_selectedCollection).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('No active listings found in $_selectedCollection.', style: const TextStyle(color: Colors.white70)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name = data['name']?.toString() ?? data['title']?.toString() ?? 'Listing';
                  final status = data['status']?.toString() ?? 'published';
                  final category = data['businessCategory']?.toString() ?? data['category']?.toString() ?? '';
                  final location = data['location']?.toString() ?? data['address']?.toString() ?? '';
                  final isVerified = data['isVerified'] == true || data['verificationStatus'] == 'approved';
                  final subTier = data['subscriptionTier']?.toString();

                  return Card(
                    color: const Color(0xFF004D40),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(name, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'published' || status == 'approved'
                                      ? Colors.greenAccent.withOpacity(0.2)
                                      : Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'published' || status == 'approved' ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          StatusBadgeWidget(isVerified: isVerified, subscriptionTier: subTier),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Category: $category', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Location: $location', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isVerified ? Colors.grey.shade700 : const Color(0xFF00E676),
                                  foregroundColor: isVerified ? Colors.white : const Color(0xFF061E12),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _toggleVerification(doc, isVerified),
                                icon: Icon(isVerified ? Icons.close : Icons.verified, size: 14),
                                label: Text(isVerified ? 'Unverify' : 'Verify ✓', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                onPressed: () => _setStatus(doc, 'published'),
                                child: const Text('Approve / Publish', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                onPressed: () => _setStatus(doc, 'suspended'),
                                child: const Text('Suspend', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                onPressed: () => _delete(doc),
                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
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

  Future<void> _toggleVerification(DocumentSnapshot<Map<String, dynamic>> doc, bool currentVerified) async {
    final nextVerified = !currentVerified;
    await doc.reference.update({
      'isVerified': nextVerified,
      'verificationStatus': nextVerified ? 'approved' : 'unverified',
      'verifiedAt': nextVerified ? FieldValue.serverTimestamp() : null,
      'verifiedBy': AppSession.email,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(nextVerified ? '✓ Profile marked as Verified by Admin' : 'Profile verification removed'),
        backgroundColor: const Color(0xFF004D40),
      ));
    }
  }

  Future<void> _setStatus(DocumentSnapshot<Map<String, dynamic>> doc, String status) async {
    await doc.reference.update({
      'status': status,
      'moderatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': AppSession.email,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status.')));
    }
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: const Text('Delete Listing?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete this listing from the database.', style: TextStyle(color: Colors.white70)),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted.')));
      }
    }
  }
}
