import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String uploader;
  int likes;
  bool isLiked;
  final List<String> comments;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.uploader,
    required this.likes,
    this.isLiked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<GalleryItem> _galleryItems = [
    GalleryItem(
      id: 'g1',
      title: 'Community Celebration',
      description: 'Captured during our spring cultural gathering in Paris.',
      imageUrl: 'https://images.unsplash.com/photo-1518972559570-9d7d79c2d2cc?w=800',
      uploader: 'Admin Team',
      likes: 18,
      comments: ['Beautiful gathering!', 'Love the energy.'],
    ),
    GalleryItem(
      id: 'g2',
      title: 'Habesha Market Stall',
      description: 'A vibrant marketplace display with traditional crafts and coffee.',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
      uploader: 'Euro Habesha',
      likes: 27,
      comments: ['Looks amazing!', 'Can I buy the pottery?'],
    ),
  ];

  final _uploadFormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isUploading = false;

  final bool _isAdmin = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _showUploadDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: const Text('Upload Gallery Image', style: TextStyle(color: Colors.white)),
          content: Form(
            key: _uploadFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      filled: true,
                      fillColor: Color(0xFF0E2E1E),
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: Color(0xFF0E2E1E),
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      filled: true,
                      fillColor: Color(0xFF0E2E1E),
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an image URL.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: _isUploading
                  ? null
                  : () {
                      if (_uploadFormKey.currentState!.validate()) {
                        final navigator = Navigator.of(context);
                        setState(() {
                          _isUploading = true;
                        });
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (!mounted) return;
                          setState(() {
                            _galleryItems.insert(
                              0,
                              GalleryItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: _titleController.text.trim(),
                                description: _descriptionController.text.trim(),
                                imageUrl: _imageUrlController.text.trim(),
                                uploader: 'Admin',
                                likes: 0,
                              ),
                            );
                            _isUploading = false;
                          });
                          navigator.pop();
                        });
                      }
                    },
              child: _isUploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF061E12)))
                  : const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  void _showComments(GalleryItem item) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E2E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Comments for ${item.title}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (item.comments.isEmpty)
                const Text('No comments yet. Be the first to share your thoughts.', style: TextStyle(color: Colors.white54)),
              if (item.comments.isNotEmpty)
                ...item.comments.map(
                  (comment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('• $comment', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: commentController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Add a comment',
                  filled: true,
                  fillColor: Color(0xFF061E12),
                  labelStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: () {
                  final text = commentController.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    item.comments.add(text);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Post Comment'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Gallery'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _showUploadDialog,
              tooltip: 'Upload Image',
            ),
        ],
      ),
      backgroundColor: const Color(0xFF061E12),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _galleryItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _galleryItems[index];
          return Card(
            color: const Color(0xFF0E2E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(
                    item.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: const Color(0xFF1E2F26),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: Colors.white30, size: 40),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(item.description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Uploaded by ${item.uploader}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          Text('${item.comments.length} comments', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(item.isLiked ? Icons.favorite : Icons.favorite_border, color: item.isLiked ? Colors.redAccent : Colors.white70),
                            onPressed: () {
                              setState(() {
                                item.isLiked = !item.isLiked;
                                item.likes += item.isLiked ? 1 : -1;
                              });
                            },
                          ),
                          Text('${item.likes} likes', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
                            icon: const Icon(Icons.comment_outlined, size: 18),
                            label: const Text('Comment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () => _showComments(item),
                          ),
                        ],
                      ),
                    ],
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
