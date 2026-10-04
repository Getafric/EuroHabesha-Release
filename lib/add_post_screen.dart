import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  // ── ፎቶ ከጋለሪ ለመምረጥ ──
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ── ፎቶ ከካሜራ ለማንሳት ──
  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ── ፖስቱን ፐብሊሽ ለማድረግ ──
  Future<void> _submitPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or an image to post.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Please sign in before posting.');
      }

      String? imageUrl;
      String? storagePath;
      if (_selectedImage != null) {
        storagePath =
            'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.uri.pathSegments.last}';
        final storageRef = FirebaseStorage.instance.ref(storagePath);
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'ownerId': user.uid,
        'authorId': user.uid,
        'authorName': user.displayName ?? user.email ?? 'Community Member',
        'text': _postController.text.trim(),
        'imageUrl': imageUrl,
        'imageStoragePath': storagePath,
        'status': 'published',
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Post published successfully.'),
          backgroundColor: Colors.green));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Post failed: $error'),
            backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        title: const Text('Create Post',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: primaryDarkGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
              ),
              onPressed: _isPosting ? null : _submitPost,
              child: _isPosting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          color: Color(0xFF061E12), strokeWidth: 2))
                  : const Text('Post',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. የተጠቃሚው ፕሮፋይል መረጃ (User Info) ──
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cardGreen,
                        backgroundImage: const NetworkImage(
                            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Getu A.', // 💡 የተጠቃሚው ስም
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cardGreen,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public,
                                      color: primaryGold, size: 12),
                                  const SizedBox(width: 4),
                                  const Text('Public',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── 2. ጽሁፍ መጻፊያ (Text Input) ──
                  TextField(
                    controller: _postController,
                    maxLines: null, // የፈለገውን ያህል መስመር መጻፍ እንዲችል
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: 'What\'s happening in the community?',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. የተመረጠውን ፎቶ ማሳያ (Image Preview) ──
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── 4. ከስር የሚቀመጡ አዝራሮች (Bottom Action Bar) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardGreen,
              border: Border(
                  top: BorderSide(color: primaryGold.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const Text('Add to your post',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.image,
                        color: Colors.greenAccent, size: 28),
                    tooltip: 'Gallery',
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.blueAccent, size: 28),
                    tooltip: 'Camera',
                    onPressed: _takePhoto,
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on,
                        color: Colors.redAccent, size: 28),
                    tooltip: 'Check in',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Location feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
