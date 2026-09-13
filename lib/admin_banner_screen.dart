import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_session.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});
  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _promoCode = TextEditingController();
  final _usageLimit = TextEditingController(text: '100');
  
  double _discountPercent = 20.0;
  final List<double> _presetDiscounts = [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 50.0];

  File? _bannerImageFile;
  final ImagePicker _picker = ImagePicker();

  String? _selectedBusinessId;
  String? _selectedBusinessName;
  Map<String, dynamic>? _selectedBusinessData;

  DateTime _startsAt = DateTime.now();
  DateTime _endsAt = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _promoCode.dispose();
    _usageLimit.dispose();
    super.dispose();
  }

  Future<void> _pickBannerImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _bannerImageFile = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!AppSession.isSuperAdmin || _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter banner title.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? uploadedImageUrl;

      if (_bannerImageFile != null && user != null) {
        final path = 'announcements/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_banner.jpg';
        final ref = FirebaseStorage.instance.ref(path);
        await ref.putFile(_bannerImageFile!);
        uploadedImageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('sponsoredBanners').add({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'imageUrl': uploadedImageUrl ?? '',
        'promoCode': _promoCode.text.trim().toUpperCase(),
        'discountPercent': _discountPercent,
        'discountText': '${_discountPercent.toInt()}% OFF',
        'usageLimit': int.tryParse(_usageLimit.text.trim()) ?? 100,
        'claimsCount': 0,
        'targetBusinessId': _selectedBusinessId ?? '',
        'targetBusinessName': _selectedBusinessName ?? '',
        'targetBusinessData': _selectedBusinessData ?? {},
        'targetRoute': '/business',
        'startsAt': Timestamp.fromDate(_startsAt),
        'endsAt': Timestamp.fromDate(_endsAt),
        'status': 'active',
        'createdBy': AppSession.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sponsored advertising banner created successfully!'),
          backgroundColor: Color(0xFF004D40),
        ));
        _title.clear();
        _body.clear();
        _promoCode.clear();
        setState(() {
          _bannerImageFile = null;
          _selectedBusinessId = null;
          _selectedBusinessName = null;
          _selectedBusinessData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Banner creation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(child: Text('Super Admin access required.', style: TextStyle(color: Colors.white70)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Create Sponsored Advertisement Banner',
          style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload banner photo, choose promotional discount, and select linked restaurant or business profile.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // ── 1. Upload Banner Image ──
        GestureDetector(
          onTap: _pickBannerImage,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              image: _bannerImageFile != null
                  ? DecorationImage(image: FileImage(_bannerImageFile!), fit: BoxFit.cover)
                  : null,
            ),
            child: _bannerImageFile == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: Color(0xFFFFD700), size: 40),
                      SizedBox(height: 6),
                      Text('Choose / Upload Banner Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('From Gallery', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  )
                : Container(
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                        onPressed: _pickBannerImage,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // ── 2. Promotion Details ──
        _field('Banner Title *', _title, hint: 'e.g., Lucy Habesha Restaurant Promo'),
        _field('Promotional Text *', _body, maxLines: 3, hint: 'e.g., Get authentic Ethiopian Kitfo and Doro Wot with exclusive 20% discount this week!'),
        _field('Promo Code *', _promoCode, hint: 'e.g., LUCY20 or ADDIS20'),

        // ── 3. Discount Percentage Dropdown ──
        const Text('Discount Percentage', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: _discountPercent,
              dropdownColor: const Color(0xFF004D40),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              isExpanded: true,
              items: _presetDiscounts.map((d) {
                return DropdownMenuItem<double>(
                  value: d,
                  child: Text('${d.toInt()}% OFF Discount', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _discountPercent = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── 4. Select Linked Business / Profile from Directory ──
        const Text('Link to Business / Restaurant Profile *', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF004D40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBusinessId,
                  hint: const Text('Select existing business profile', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  dropdownColor: const Color(0xFF004D40),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'starter_lucy',
                      child: Text('Lucy Habesha Restaurant (Lyon)', style: TextStyle(color: Colors.white)),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'starter_konjo',
                      child: Text('Konjo Beauty Salon (Paris)', style: TextStyle(color: Colors.white)),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'starter_supermarket',
                      child: Text('Habesha Supermarket (Lyon)', style: TextStyle(color: Colors.white)),
                    ),
                    ...docs.map((doc) {
                      final name = doc.data()['name'] ?? doc.data()['title'] ?? 'Business';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(name.toString(), style: const TextStyle(color: Colors.white)),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBusinessId = val;
                        if (val == 'starter_lucy') {
                          _selectedBusinessName = 'Lucy Habesha Restaurant';
                          _selectedBusinessData = {
                            'name': 'Lucy Habesha Restaurant',
                            'location': 'Lyon, France',
                            'address': '12 Rue de Marseille, 69007 Lyon, France',
                            'phone': 'tel:+33400000000',
                            'rating': '4.9 (320 reviews)',
                            'badge': 'Premium',
                            'category': 'Restaurants / Food',
                          };
                        } else {
                          final match = docs.where((d) => d.id == val).firstOrNull;
                          _selectedBusinessName = match?.data()['name'] ?? 'Business';
                          _selectedBusinessData = match?.data();
                        }
                      });
                    }
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        _field('Usage Limit (Optional)', _usageLimit, keyboardType: TextInputType.number, hint: 'e.g., 100 claims'),

        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.campaign, color: Color(0xFF061E12)),
          label: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF061E12), strokeWidth: 2))
              : const Text('Publish Sponsored Banner 🚀', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF004D40),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
