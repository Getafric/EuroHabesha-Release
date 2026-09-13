import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_session.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _mediaFile;
  String _mediaType = 'text';
  bool _isPosting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _mediaFile = File(file.path);
        _mediaType = 'photo';
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (file != null) {
      setState(() {
        _mediaFile = File(file.path);
        _mediaType = 'shortVideo';
      });
    }
  }

  Future<void> _publish() async {
    if (!AppSession.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Super Admin access required.')));
      return;
    }

    if (_messageController.text.trim().isEmpty && _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add text, photo, or short video.')));
      return;
    }

    setState(() => _isPosting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? mediaUrl;
      String? mediaStoragePath;
      if (_mediaFile != null) {
        mediaStoragePath = 'announcements/${user?.uid}/${DateTime.now().millisecondsSinceEpoch}_${_mediaFile!.uri.pathSegments.last}';
        final storageRef = FirebaseStorage.instance.ref(mediaStoragePath);
        await storageRef.putFile(_mediaFile!);
        mediaUrl = await storageRef.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('adminAnnouncements').add({
        'message': _messageController.text.trim(),
        'mediaType': _mediaType,
        'mediaUrl': mediaUrl,
        'mediaStoragePath': mediaStoragePath,
        'authorId': user?.uid,
        'authorEmail': AppSession.email,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'official': true,
      });

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Official announcement published.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Create Announcement/Post', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _publish,
            child: Text(_isPosting ? 'Posting...' : 'Post', style: const TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        children: [
          TextField(
            controller: _messageController,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Write an official update, news, feedback request, or announcement...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          if (_mediaFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(_mediaType == 'photo' ? Icons.image : Icons.videocam, color: primaryGold),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_mediaFile!.path.split(Platform.pathSeparator).last, style: const TextStyle(color: Colors.white70))),
                  IconButton(onPressed: () => setState(() => _mediaFile = null), icon: const Icon(Icons.close, color: Colors.white54)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _mediaButton(Icons.image, 'Photo', _pickImage)),
              const SizedBox(width: 12),
              Expanded(child: _mediaButton(Icons.videocam, 'Short Video', _pickVideo)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mediaButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primaryGold),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: primaryGold),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
