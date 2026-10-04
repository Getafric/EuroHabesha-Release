import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HabeshaConnectFeedScreen extends StatefulWidget {
  const HabeshaConnectFeedScreen({super.key});

  @override
  State<HabeshaConnectFeedScreen> createState() =>
      _HabeshaConnectFeedScreenState();
}

class _HabeshaConnectFeedScreenState extends State<HabeshaConnectFeedScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  static const Color softText = Color(0xFFD5DFDA);
  static const Color mutedText = Color(0xFFAAB9B2);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedTab = 1;

  String? _userCity;
  String? _userCountry;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadingLocation = true;
      });
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null && mounted) {
          final city = _firstString([
            data['city'],
            data['ville'],
            data['locationCity'],
          ]);

          final country = _firstString([
            data['country'],
            data['pays'],
            data['locationCountry'],
          ]);

          setState(() {
            _userCity = city;
            _userCountry = country;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Erreur chargement localisation utilisateur: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    return _postsCollection
        .where('status', isEqualTo: 'published')
        .limit(100)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
  ) {
    final result =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(posts);

    if (_selectedTab == 0) {
      result.sort((a, b) {
        final aData = a.data();
        final bData = b.data();

        final aLikes = _intValue(aData['likeCount']);
        final bLikes = _intValue(bData['likeCount']);

        final aComments = _intValue(aData['commentCount']);
        final bComments = _intValue(bData['commentCount']);

        final aScore = aLikes + (aComments * 2);
        final bScore = bLikes + (bComments * 2);

        if (aScore != bScore) {
          return bScore.compareTo(aScore);
        }

        return _dateValue(
          bData['createdAt'],
        ).compareTo(
          _dateValue(aData['createdAt']),
        );
      });
    } else if (_selectedTab == 2) {
      result.retainWhere(_isNearbyPost);

      result.sort((a, b) {
        return _dateValue(
          b.data()['createdAt'],
        ).compareTo(
          _dateValue(a.data()['createdAt']),
        );
      });
    } else {
      result.sort((a, b) {
        return _dateValue(
          b.data()['createdAt'],
        ).compareTo(
          _dateValue(a.data()['createdAt']),
        );
      });
    }

    return result;
  }

  bool _isNearbyPost(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final postCity = _firstString([
      data['city'],
      data['ville'],
    ]);

    final postCountry = _firstString([
      data['country'],
      data['pays'],
    ]);

    if (_userCity != null && postCity != null) {
      if (_normalize(_userCity!) == _normalize(postCity)) {
        return true;
      }
    }

    if (_userCountry != null && postCountry != null) {
      if (_normalize(_userCountry!) == _normalize(postCountry)) {
        return true;
      }
    }

    return false;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u');
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  DateTime _dateValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final date = _dateValue(value);

    if (date.millisecondsSinceEpoch == 0) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l’instant';
    }

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _categoryName(Map<String, dynamic> data) {
    return _firstString([
          data['connectCategory'],
          data['communityCategory'],
          data['category'],
          data['type'],
        ]) ??
        'Habesha Connect';
  }

  String? _locationText(Map<String, dynamic> data) {
    final city = _firstString([
      data['city'],
      data['ville'],
    ]);

    final country = _firstString([
      data['country'],
      data['pays'],
    ]);

    if (city != null && country != null) {
      return '$city, $country';
    }

    return city ?? country;
  }

  Future<void> _refreshFeed() async {
    if (mounted) {
      setState(() {});
    }

    await _loadUserLocation();
  }

  void _requireAccount() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.isAnonymous) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          title: const Text(
            'Compte requis',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Vous devez être connecté avec un compte pour aimer '
            'une publication ou écrire un commentaire.',
            style: TextStyle(
              color: softText,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Fermer',
                style: TextStyle(color: primaryGold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.groups_rounded,
              color: primaryGold,
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Habesha Connect',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshFeed,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _postsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryGold,
                    ),
                  );
                }

                final documents = snapshot.data?.docs ?? [];
                final posts = _sortPosts(documents);

                if (posts.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: primaryDarkGreen,
                  backgroundColor: primaryGold,
                  onRefresh: _refreshFeed,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      14,
                      14,
                      30,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _FeedPostCard(
                        key: ValueKey(posts[index].id),
                        document: posts[index],
                        formatDate: _formatDate,
                        categoryName: _categoryName,
                        locationText: _locationText,
                        requireAccount: _requireAccount,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: primaryDarkGreen,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          _buildTab(
            index: 0,
            icon: Icons.local_fire_department_rounded,
            label: 'Populaire',
          ),
          const SizedBox(width: 8),
          _buildTab(
            index: 1,
            icon: Icons.access_time_rounded,
            label: 'Récent',
          ),
          const SizedBox(width: 8),
          _buildTab(
            index: 2,
            icon: Icons.location_on_rounded,
            label: 'Près de moi',
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 7,
          ),
          decoration: BoxDecoration(
            color: selected ? primaryGold : cardGreen.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? primaryGold : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? primaryDarkGreen : Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? primaryDarkGreen : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String message;
    IconData icon;

    if (_selectedTab == 2) {
      if (_loadingLocation) {
        title = 'Recherche en cours';
        message = 'Nous recherchons les publications proches de vous.';
        icon = Icons.location_searching_rounded;
      } else if (_userCity == null && _userCountry == null) {
        title = 'Localisation non renseignée';
        message = 'Ajoutez votre ville ou votre pays à votre profil '
            'pour voir les publications près de vous.';
        icon = Icons.location_off_rounded;
      } else {
        title = 'Rien près de vous';
        message = 'Aucune publication Habesha Connect ne correspond '
            'actuellement à votre ville ou votre pays.';
        icon = Icons.location_on_rounded;
      }
    } else if (_selectedTab == 0) {
      title = 'Pas encore de publications populaires';
      message = 'Les publications qui reçoivent le plus de likes '
          'et de commentaires apparaîtront ici.';
      icon = Icons.local_fire_department_rounded;
    } else {
      title = 'Aucune publication';
      message = 'Les nouvelles publications Habesha Connect '
          'apparaîtront ici après validation par l’administration.';
      icon = Icons.dynamic_feed_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: cardGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGold.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                icon,
                size: 38,
                color: primaryGold,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Impossible de charger le fil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: primaryDarkGreen,
              ),
              onPressed: _refreshFeed,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final String Function(dynamic) formatDate;
  final String Function(Map<String, dynamic>) categoryName;
  final String? Function(Map<String, dynamic>) locationText;
  final VoidCallback requireAccount;

  const _FeedPostCard({
    super.key,
    required this.document,
    required this.formatDate,
    required this.categoryName,
    required this.locationText,
    required this.requireAccount,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  static const Color softText = Color(0xFFD5DFDA);
  static const Color mutedText = Color(0xFFAAB9B2);

  @override
  Widget build(BuildContext context) {
    final data = document.data();

    final text = _firstString([
      data['text'],
      data['content'],
      data['description'],
      data['question'],
    ]);

    final authorName = _firstString([
      data['authorName'],
      data['displayName'],
      data['name'],
    ]);

    final imageUrl = _firstString([
      data['imageUrl'],
      data['image'],
      data['photoUrl'],
    ]);

    final category = categoryName(data);
    final location = locationText(data);
    final date = formatDate(data['createdAt']);

    final initial = authorName != null && authorName.isNotEmpty
        ? authorName[0].toUpperCase()
        : 'H';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: primaryDarkGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: primaryGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName ?? 'Membre Habesha',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: primaryGold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (location != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: mutedText,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (date.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 6,
                      top: 2,
                    ),
                    child: Text(
                      date,
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (text != null && text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: softText,
                ),
              ),
            ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 230,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return Container(
                  height: 230,
                  color: primaryDarkGreen,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryGold,
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  height: 180,
                  color: primaryDarkGreen,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 42,
                    color: mutedText,
                  ),
                );
              },
            ),
          _PostActions(
            postId: document.id,
            postData: data,
            requireAccount: requireAccount,
          ),
        ],
      ),
    );
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}

class _PostActions extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;
  final VoidCallback requireAccount;

  const _PostActions({
    required this.postId,
    required this.postData,
    required this.requireAccount,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);

  CollectionReference<Map<String, dynamic>> get _postRef =>
      FirebaseFirestore.instance.collection('posts');

  CollectionReference<Map<String, dynamic>> get _likesRef =>
      _postRef.doc(postId).collection('likes');

  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _postRef.doc(postId).collection('comments');

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _isRealAccount {
    final user = _user;
    return user != null && !user.isAnonymous;
  }

  Stream<int> _likeCountStream() {
    return _likesRef.snapshots().map(
          (snapshot) => snapshot.size,
        );
  }

  Stream<int> _commentCountStream() {
    return _commentsRef.snapshots().map(
          (snapshot) => snapshot.size,
        );
  }

  Future<void> _toggleLike(BuildContext context) async {
    if (!_isRealAccount) {
      requireAccount();
      return;
    }

    final user = _user!;

    final likeRef = _likesRef.doc(user.uid);
    final postDocument = _postRef.doc(postId);

    try {
      final existing = await likeRef.get();

      if (existing.exists) {
        await likeRef.delete();

        try {
          await postDocument.update({
            'likeCount': FieldValue.increment(-1),
          });
        } catch (e) {
          debugPrint('Erreur compteur like: $e');
        }
      } else {
        await likeRef.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        try {
          await postDocument.update({
            'likeCount': FieldValue.increment(1),
          });
        } catch (e) {
          debugPrint('Erreur compteur like: $e');
        }

        await _createLikeNotification(
          postDocument: postDocument,
          actorId: user.uid,
          actorName: user.displayName ?? 'Membre Habesha',
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Impossible de modifier le like : $e',
          ),
        ),
      );
    }
  }

  Future<void> _createLikeNotification({
    required DocumentReference<Map<String, dynamic>> postDocument,
    required String actorId,
    required String actorName,
  }) async {
    try {
      final postSnapshot = await postDocument.get();

      if (!postSnapshot.exists) {
        return;
      }

      final data = postSnapshot.data();

      final recipientId = data?['authorId']?.toString();

      if (recipientId == null ||
          recipientId.isEmpty ||
          recipientId == actorId) {
        return;
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'senderId': actorId,
        'senderName': actorName,
        'type': 'like',
        'postId': postId,
        'message': '$actorName a aimé votre publication.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Notification like non créée: $e');
    }
  }

  Future<void> _showComments(BuildContext context) async {
    if (!_isRealAccount) {
      requireAccount();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CommentsSheet(
          commentsRef: _commentsRef,
          postRef: _postRef.doc(postId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: primaryDarkGreen,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          StreamBuilder<bool>(
            stream: _likeStateStream(),
            builder: (context, snapshot) {
              final liked = snapshot.data ?? false;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleLike(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 21,
                        color: liked ? Colors.redAccent : Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      StreamBuilder<int>(
                        stream: _likeCountStream(),
                        builder: (context, countSnapshot) {
                          return Text(
                            '${countSnapshot.data ?? _initialLikeCount()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showComments(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  StreamBuilder<int>(
                    stream: _commentCountStream(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? _initialCommentCount()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showComments(context),
            icon: const Icon(
              Icons.reply_rounded,
              size: 18,
            ),
            label: const Text('Répondre'),
            style: TextButton.styleFrom(
              foregroundColor: primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Stream<bool> _likeStateStream() async* {
    if (!_isRealAccount) {
      yield false;
      return;
    }

    await for (final snapshot in _likesRef.doc(_user!.uid).snapshots()) {
      yield snapshot.exists;
    }
  }

  int _initialLikeCount() {
    final value = postData['likeCount'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  int _initialCommentCount() {
    final value = postData['commentCount'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }
}

class _CommentsSheet extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> commentsRef;
  final DocumentReference<Map<String, dynamic>> postRef;

  const _CommentsSheet({
    required this.commentsRef,
    required this.postRef,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  static const Color softText = Color(0xFFD5DFDA);
  static const Color mutedText = Color(0xFFAAB9B2);

  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _sending = false;

  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _isRealAccount {
    final user = _user;
    return user != null && !user.isAnonymous;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'maintenant';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} j';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _startReply({
    required String commentId,
    required String authorName,
  }) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
    });

    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });

    _controller.clear();
  }

  Future<void> _sendComment() async {
    if (!_isRealAccount) {
      return;
    }

    final text = _controller.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    final user = _user!;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      final authorName = _firstString([
            userData?['displayName'],
            userData?['name'],
            user.displayName,
          ]) ??
          'Membre Habesha';

      final parentCommentId = _replyingToCommentId;

      final newCommentRef = widget.commentsRef.doc();

      await newCommentRef.set({
        'text': text,
        'authorId': user.uid,
        'authorName': authorName,
        'authorEmail': user.email ?? '',
        'parentCommentId': parentCommentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await widget.postRef.update({
        'commentCount': FieldValue.increment(1),
      });

      await _createCommentNotifications(
        actorId: user.uid,
        actorName: authorName,
        parentCommentId: parentCommentId,
        text: text,
      );

      _controller.clear();

      if (mounted) {
        setState(() {
          _replyingToCommentId = null;
          _replyingToAuthorName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Impossible d’ajouter le commentaire : $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _createCommentNotifications({
    required String actorId,
    required String actorName,
    required String? parentCommentId,
    required String text,
  }) async {
    try {
      final recipients = <String>{};

      final postSnapshot = await widget.postRef.get();

      if (postSnapshot.exists) {
        final postData = postSnapshot.data();

        final postAuthorId = postData?['authorId']?.toString();

        if (postAuthorId != null &&
            postAuthorId.isNotEmpty &&
            postAuthorId != actorId) {
          recipients.add(postAuthorId);
        }
      }

      if (parentCommentId != null && parentCommentId.isNotEmpty) {
        final parentSnapshot =
            await widget.commentsRef.doc(parentCommentId).get();

        if (parentSnapshot.exists) {
          final parentData = parentSnapshot.data();

          final parentAuthorId = parentData?['authorId']?.toString();

          if (parentAuthorId != null &&
              parentAuthorId.isNotEmpty &&
              parentAuthorId != actorId) {
            recipients.add(parentAuthorId);
          }
        }
      }

      final commentsSnapshot = await widget.commentsRef.limit(100).get();

      for (final document in commentsSnapshot.docs) {
        final data = document.data();

        final participantId = data['authorId']?.toString();

        if (participantId != null &&
            participantId.isNotEmpty &&
            participantId != actorId) {
          recipients.add(participantId);
        }
      }

      if (recipients.isEmpty) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final recipientId in recipients) {
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();

        final type = parentCommentId == null ? 'comment' : 'commentReply';

        final message = parentCommentId == null
            ? '$actorName a commenté votre publication.'
            : '$actorName a répondu dans une discussion à laquelle vous participez.';

        batch.set(notificationRef, {
          'recipientId': recipientId,
          'senderId': actorId,
          'senderName': actorName,
          'type': type,
          'postId': widget.postRef.id,
          'commentId': parentCommentId,
          'message': message,
          'preview': text.length > 120 ? '${text.substring(0, 120)}...' : text,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Notifications commentaires non créées: $e',
      );
    }
  }

  Widget _buildCommentItem(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        repliesByParent,
  ) {
    final data = document.data();

    final authorName = _firstString([
          data['authorName'],
          data['displayName'],
        ]) ??
        'Membre Habesha';

    final text = _firstString([
          data['text'],
          data['content'],
        ]) ??
        '';

    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'H';

    final replies = repliesByParent[document.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: cardGreen,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(data['createdAt']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: softText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextButton.icon(
                        onPressed: () {
                          _startReply(
                            commentId: document.id,
                            authorName: authorName,
                          );
                        },
                        icon: const Icon(
                          Icons.reply_rounded,
                          size: 15,
                        ),
                        label: const Text('Répondre'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryGold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: 38,
              bottom: 8,
            ),
            child: Column(
              children: replies
                  .map(
                    (reply) => _buildReplyItem(
                      reply,
                      repliesByParent,
                      depth: 0,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyItem(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        repliesByParent, {
    required int depth,
  }) {
    final data = document.data();

    final authorName = _firstString([
          data['authorName'],
          data['displayName'],
        ]) ??
        'Membre Habesha';

    final text = _firstString([
          data['text'],
          data['content'],
        ]) ??
        '';

    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'H';

    final nestedReplies = repliesByParent[document.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: primaryGold.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: cardGreen,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardGreen.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(data['createdAt']),
                            style: const TextStyle(
                              fontSize: 9,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: softText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      TextButton.icon(
                        onPressed: () {
                          _startReply(
                            commentId: document.id,
                            authorName: authorName,
                          );
                        },
                        icon: const Icon(
                          Icons.reply_rounded,
                          size: 14,
                        ),
                        label: const Text('Répondre'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryGold,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (nestedReplies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Column(
              children: nestedReplies
                  .map(
                    (reply) => _buildReplyItem(
                      reply,
                      repliesByParent,
                      depth: depth + 1,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.84,
        decoration: const BoxDecoration(
          color: primaryDarkGreen,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Commentaires',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGold,
                ),
              ),
              if (_replyingToCommentId != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 17,
                        color: primaryGold,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Réponse à ${_replyingToAuthorName ?? 'Membre Habesha'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: softText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _cancelReply,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const Divider(
                height: 1,
                color: Colors.white12,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: widget.commentsRef
                      .orderBy(
                        'createdAt',
                        descending: false,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Impossible de charger les commentaires.\n'
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: mutedText,
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: primaryGold,
                        ),
                      );
                    }

                    final comments = snapshot.data?.docs ?? [];

                    if (comments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: mutedText,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aucun commentaire pour le moment.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Soyez le premier à répondre.',
                                style: TextStyle(
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final repliesByParent = <String,
                        List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

                    final rootComments =
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                    for (final comment in comments) {
                      final data = comment.data();

                      final parentId = data['parentCommentId']?.toString();

                      if (parentId == null || parentId.isEmpty) {
                        rootComments.add(comment);
                      } else {
                        repliesByParent
                            .putIfAbsent(
                              parentId,
                              () => [],
                            )
                            .add(comment);
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        14,
                        14,
                        18,
                      ),
                      itemCount: rootComments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentItem(
                          rootComments[index],
                          repliesByParent,
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  8,
                ),
                decoration: const BoxDecoration(
                  color: primaryDarkGreen,
                  border: Border(
                    top: BorderSide(
                      color: Colors.white12,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? 'Écrire une réponse...'
                              : 'Écrire un commentaire...',
                          hintStyle: const TextStyle(
                            color: mutedText,
                          ),
                          filled: true,
                          fillColor: cardGreen,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: primaryGold,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: Material(
                        color: primaryGold,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _sending ? null : _sendComment,
                          child: Center(
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryDarkGreen,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: primaryDarkGreen,
                                    size: 21,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
