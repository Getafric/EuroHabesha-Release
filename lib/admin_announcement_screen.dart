import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_session.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({
    super.key,
    this.announcementId,
  });

  final String? announcementId;

  bool get isEditing =>
      announcementId != null && announcementId!.trim().isNotEmpty;

  @override
  State<AdminAnnouncementScreen> createState() =>
      _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();

  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final ImagePicker _picker = ImagePicker();

  File? _mediaFile;
  String? _existingMediaUrl;
  String? _existingMediaStoragePath;

  String _mediaType = 'text';
  bool _isPosting = false;
  bool _isPoll = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadAnnouncement();
    }
  }

  Future<void> _loadAnnouncement() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('adminAnnouncements')
          .doc(widget.announcementId)
          .get();

      if (!snapshot.exists) {
        throw Exception('Official update not found.');
      }

      final data = snapshot.data() ?? {};

      _messageController.text = data['message']?.toString() ?? '';

      _mediaType = data['mediaType']?.toString() ?? 'text';

      _existingMediaUrl = data['mediaUrl']?.toString();

      _existingMediaStoragePath = data['mediaStoragePath']?.toString();

      _isPoll = data['postType']?.toString() == 'poll';

      if (_isPoll) {
        _pollQuestionController.text = data['pollQuestion']?.toString() ?? '';

        final rawOptions = data['pollOptions'];

        if (rawOptions is List) {
          final labels = rawOptions
              .whereType<Map>()
              .map(
                (option) => option['label']?.toString().trim() ?? '',
              )
              .where((label) => label.isNotEmpty)
              .toList();

          if (labels.length >= 2) {
            for (final controller in _pollOptionControllers) {
              controller.dispose();
            }

            _pollOptionControllers.clear();

            for (final label in labels) {
              _pollOptionControllers.add(
                TextEditingController(text: label),
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load update: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pollQuestionController.dispose();

    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file != null) {
      setState(() {
        _mediaFile = File(file.path);
        _mediaType = 'photo';
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (file != null) {
      setState(() {
        _mediaFile = File(file.path);
        _mediaType = 'shortVideo';
      });
    }
  }

  void _togglePoll() {
    setState(() {
      _isPoll = !_isPoll;
    });
  }

  void _addPollOption() {
    if (_pollOptionControllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 poll options.'),
        ),
      );
      return;
    }

    setState(() {
      _pollOptionControllers.add(
        TextEditingController(),
      );
    });
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= 2) {
      return;
    }

    final controller = _pollOptionControllers[index];

    setState(() {
      _pollOptionControllers.removeAt(index);
    });

    controller.dispose();
  }

  Future<void> _publish() async {
    if (!AppSession.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super Admin access required.'),
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    final pollQuestion = _pollQuestionController.text.trim();

    final pollOptions = _pollOptionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (_isPoll) {
      if (pollQuestion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a poll question.'),
          ),
        );
        return;
      }

      if (pollOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least 2 poll options.'),
          ),
        );
        return;
      }
    } else if (message.isEmpty &&
        _mediaFile == null &&
        (_existingMediaUrl == null || _existingMediaUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add text, photo, short video, or create a poll.',
          ),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      String? mediaUrl = _existingMediaUrl;
      String? mediaStoragePath = _existingMediaStoragePath;

      if (_mediaFile != null) {
        final oldStoragePath = _existingMediaStoragePath;

        mediaStoragePath = 'announcements/${user?.uid}/'
            '${DateTime.now().millisecondsSinceEpoch}_'
            '${_mediaFile!.uri.pathSegments.last}';

        final storageRef = FirebaseStorage.instance.ref(mediaStoragePath);

        await storageRef.putFile(_mediaFile!);
        mediaUrl = await storageRef.getDownloadURL();

        if (widget.isEditing &&
            oldStoragePath != null &&
            oldStoragePath.isNotEmpty &&
            oldStoragePath != mediaStoragePath) {
          try {
            await FirebaseStorage.instance.ref(oldStoragePath).delete();
          } catch (_) {
            // La sauvegarde continue même si l'ancien média
            // n'existe déjà plus dans Storage.
          }
        }
      }

      final pollData = pollOptions.asMap().entries.map((entry) {
        return {
          'id': 'option_${entry.key + 1}',
          'label': entry.value,
        };
      }).toList();

      final announcementData = <String, dynamic>{
        'message': message,
        'postType': _isPoll ? 'poll' : 'announcement',
        'mediaType': mediaUrl == null ? 'text' : _mediaType,
        'mediaUrl': mediaUrl,
        'mediaStoragePath': mediaStoragePath,
        'official': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isPoll) {
        announcementData.addAll({
          'pollQuestion': pollQuestion,
          'pollOptions': pollData,
        });
      } else {
        announcementData.addAll({
          'pollQuestion': FieldValue.delete(),
          'pollOptions': FieldValue.delete(),
          'pollClosed': FieldValue.delete(),
          'pollClosedAt': FieldValue.delete(),
        });
      }

      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('adminAnnouncements')
            .doc(widget.announcementId)
            .update(announcementData);
      } else {
        await FirebaseFirestore.instance.collection('adminAnnouncements').add({
          ...announcementData,
          'authorId': user?.uid,
          'authorEmail': AppSession.email,
          'createdAt': FieldValue.serverTimestamp(),
          'likesCount': 0,
          'commentsCount': 0,
          if (_isPoll) 'pollClosed': false,
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Official update saved.'
                : _isPoll
                    ? 'Official poll published.'
                    : 'Official announcement published.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Update failed: $e' : 'Announcement failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryDarkGreen,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryGold,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Official Update' : 'Create Official Update',
          style: const TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(
          color: primaryGold,
        ),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _publish,
            child: Text(
              _isPosting
                  ? (widget.isEditing ? 'Saving...' : 'Posting...')
                  : (widget.isEditing ? 'Save' : 'Post'),
              style: const TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: [
          TextField(
            controller: _messageController,
            minLines: 5,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText:
                  'Write an official update, news, feedback request, or announcement...',
              hintStyle: const TextStyle(
                color: Colors.white38,
              ),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_mediaFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _mediaType == 'photo' ? Icons.image : Icons.videocam,
                    color: primaryGold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mediaFile!.path.split(Platform.pathSeparator).last,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _mediaFile = null;
                        _mediaType = 'text';
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          if (_mediaFile != null) const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _mediaButton(
                  Icons.image,
                  'Photo',
                  _pickImage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _mediaButton(
                  Icons.videocam,
                  'Short Video',
                  _pickVideo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _mediaButton(
                  Icons.poll_outlined,
                  _isPoll ? 'Poll ✓' : 'Poll',
                  _togglePoll,
                ),
              ),
            ],
          ),
          if (_isPoll) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryGold.withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.poll_outlined,
                        color: primaryGold,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Create Poll',
                        style: TextStyle(
                          color: primaryGold,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pollQuestionController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _pollDecoration(
                      'Poll question',
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < _pollOptionControllers.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pollOptionControllers[i],
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _pollDecoration(
                              'Option ${i + 1}',
                            ),
                          ),
                        ),
                        if (_pollOptionControllers.length > 2)
                          IconButton(
                            onPressed: () => _removePollOption(i),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextButton.icon(
                    onPressed: _addPollOption,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: primaryGold,
                    ),
                    label: const Text(
                      'Add option',
                      style: TextStyle(
                        color: primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Members can vote once and change their choice while the poll is open.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _pollDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white38,
      ),
      filled: true,
      fillColor: primaryDarkGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _mediaButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: primaryGold,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
      onPressed: onTap,
      icon: Icon(
        icon,
        color: primaryGold,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}
