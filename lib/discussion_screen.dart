import 'package:flutter/material.dart';
import 'models.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _newPostController = TextEditingController();
  String _selectedCategory = 'All';

  final List<DiscussionPost> _discussions = [
    DiscussionPost(
      id: 'd1',
      authorName: 'Yonas Kifle',
      authorTitle: 'Platinum Lawyer',
      authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      category: 'Legal Aid',
      content: 'Important updates regarding the new Schengen visa regulations and naturalization requirements in Germany starting this quarter. Let me know if you seek counsel.',
      likes: 31,
      commentsCount: 9,
      timestamp: '1 hour ago',
    ),
    DiscussionPost(
      id: 'd2',
      authorName: 'Helen Berhe',
      authorTitle: 'Gold Business',
      authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      category: 'Housing Hub',
      content: 'Seeking a cozy studio apartment for an international Habesha student arriving in London (Westminster area) next month. Budget is around £850/mo. DM if you have leads!',
      likes: 12,
      commentsCount: 4,
      timestamp: '3 hours ago',
    ),
  ];

  void _addNewPost() {
    if (_newPostController.text.trim().isEmpty) return;

    setState(() {
      _discussions.insert(
        0,
        DiscussionPost(
          id: DateTime.now().toString(),
          authorName: 'You (Verified Member)',
          authorTitle: 'Member',
          authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
          category: _selectedCategory == 'All' ? 'General' : _selectedCategory,
          content: _newPostController.text,
          likes: 0,
          commentsCount: 0,
          timestamp: 'Just now',
        ),
      );
    });

    _newPostController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Discussion group query posted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _discussions
        : _discussions.where((d) => d.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        title: const Text(
          'DIASPORA FORUMS & DISCUSSION GROUPS',
          style: TextStyle(
            color: Color(0xFFF59E0B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Post Creator Header
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0E2E1E),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF061E12),
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF061E12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _newPostController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Share, ask or seek guidance...',
                            hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFF59E0B), size: 20),
                      onPressed: _addNewPost,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category selection chip
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Legal Aid', 'Housing Hub', 'Business Listings', 'General'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF061E12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : Colors.white10),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF061E12) : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Message Board / List of Threads
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No discussions posted under this category yet.',
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final d = filtered[index];
                      return Card(
                        color: const Color(0xFF0E2E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(d.authorAvatar),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            d.authorName,
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              d.authorTitle,
                                              style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Category: ${d.category} • ${d.timestamp}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                d.content,
                                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.4),
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          d.isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: d.isLiked ? Colors.red : Colors.white54,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            d.isLiked = !d.isLiked;
                                            d.likes = d.isLiked ? d.likes + 1 : d.likes - 1;
                                          });
                                        },
                                      ),
                                      Text('${d.likes} Likes', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.comment_outlined, color: Colors.white54, size: 16),
                                      const SizedBox(width: 6),
                                      Text('${d.commentsCount} Comments', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Discussion comments are loading offline...')),
                                      );
                                    },
                                    child: const Text(
                                      'Reply / መልስ',
                                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

