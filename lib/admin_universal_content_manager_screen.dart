import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dynamic_submission_screen.dart';
import 'app_session.dart';
import 'status_badge_widget.dart';

class AdminUniversalContentManagerScreen extends StatefulWidget {
  const AdminUniversalContentManagerScreen({super.key});

  @override
  State<AdminUniversalContentManagerScreen> createState() =>
      _AdminUniversalContentManagerScreenState();
}

class _AdminUniversalContentManagerScreenState
    extends State<AdminUniversalContentManagerScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  String _selectedSection = 'businesses';

  final List<Map<String, String>> _sections = [
    {
      'key': 'businesses',
      'label': 'Businesses & Restaurants',
    },
    {
      'key': 'jobs',
      'label': 'Jobs & Professionals',
    },
    {
      'key': 'events',
      'label': 'Events',
    },
    {
      'key': 'marketplace',
      'label': 'Marketplace Items',
    },
    {
      'key': 'posts',
      'label': 'Community Feed Posts',
    },
  ];

  String get _selectedSectionLabel {
    for (final section in _sections) {
      if (section['key'] == _selectedSection) {
        return section['label'] ?? _selectedSection;
      }
    }

    return _selectedSection;
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(
        child: Text(
          'Super Admin access required.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _buildSectionSwitcher(),
            _buildManagementHeader(constraints),
            Expanded(
              child: _buildItemsStream(),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION SWITCHER
  // ---------------------------------------------------------------------------

  Widget _buildSectionSwitcher() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          final key = section['key'] ?? '';
          final label = section['label'] ?? key;
          final isSelected = _selectedSection == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              selected: isSelected,
              selectedColor: primaryGold,
              backgroundColor: cardGreen,
              side: BorderSide(
                color: isSelected
                    ? primaryGold
                    : Colors.white.withValues(alpha: 0.08),
              ),
              labelStyle: TextStyle(
                color: isSelected ? primaryDarkGreen : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (!selected || key.isEmpty) {
                  return;
                }

                setState(() {
                  _selectedSection = key;
                });
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MANAGEMENT HEADER
  // ---------------------------------------------------------------------------

  Widget _buildManagementHeader(BoxConstraints constraints) {
    final isNarrow = constraints.maxWidth < 500;

    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Managing: $_selectedSectionLabel',
              style: TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildAddButton(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Managing: $_selectedSectionLabel',
              style: TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: primaryDarkGreen,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(
        Icons.add,
        size: 17,
      ),
      label: const Text(
        'Add Content',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      onPressed: () => _showAddEditDialog(null),
    );
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE STREAM
  // ---------------------------------------------------------------------------

  Widget _buildItemsStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection(_selectedSection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryGold,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildContentCard(docs[index]);
          },
        );
      },
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load this content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown Firestore error.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: primaryGold,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'No items in this category yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tap "+ Add Content" to create one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT CARD
  // ---------------------------------------------------------------------------

  Widget _buildContentCard(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final title = _firstNonEmpty([
      data['title'],
      data['name'],
      data['text'],
      'Item',
    ]);

    final subtitle = _firstNonEmpty([
      data['location'],
      data['address'],
      data['category'],
      data['type'],
      '',
    ]);

    final status = data['status']?.toString() ?? 'published';

    final isVerified = data['isVerified'] == true ||
        data['verificationStatus']?.toString().toLowerCase() == 'approved';

    final subscriptionTier = data['subscriptionTier']?.toString();

    final imageUrl = _firstNonEmpty([
      data['imageUrl'],
      data['image'],
      data['logoUrl'],
      '',
    ]);

    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContentHeader(
              title: title,
              subtitle: subtitle,
              status: status,
              isVerified: isVerified,
              subscriptionTier: subscriptionTier,
              imageUrl: imageUrl,
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.white12,
              height: 1,
            ),
            const SizedBox(height: 8),
            _buildActionButtons(
              doc: doc,
              isVerified: isVerified,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentHeader({
    required String title,
    required String subtitle,
    required String status,
    required bool isVerified,
    required String? subscriptionTier,
    required String imageUrl,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThumbnail(imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildStatusBadge(status),
                  StatusBadgeWidget(
                    isVerified: isVerified,
                    subscriptionTier: subscriptionTier,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderThumbnail();
          },
        ),
      );
    }

    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: primaryGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.article_outlined,
        color: primaryGold,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalizedStatus = status.toLowerCase();

    final isPositive =
        normalizedStatus == 'published' || normalizedStatus == 'approved';

    final badgeColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: badgeColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION BUTTONS
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons({
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required bool isVerified,
  }) {
    final canVerify =
        _selectedSection == 'businesses' || _selectedSection == 'jobs';

    final isEvent = _selectedSection == 'events';

    return Wrap(
      spacing: 8,
      runSpacing: 7,
      children: [
        if (isEvent)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryGold,
              side: BorderSide(
                color: primaryGold,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              minimumSize: const Size(0, 34),
            ),
            onPressed: () => _showEventDetails(doc),
            icon: const Icon(
              Icons.visibility_outlined,
              size: 14,
            ),
            label: const Text(
              'View Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGold,
            foregroundColor: primaryDarkGreen,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            minimumSize: const Size(0, 34),
          ),
          onPressed: () {
            if (isEvent) {
              _openEventEditor(doc);
            } else {
              _showAddEditDialog(doc);
            }
          },
          icon: const Icon(
            Icons.edit,
            size: 14,
          ),
          label: Text(
            isEvent ? 'Edit Event' : 'Edit / Replace Photo',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        if (canVerify)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isVerified ? Colors.grey.shade700 : const Color(0xFF00E676),
              foregroundColor: isVerified ? Colors.white : primaryDarkGreen,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              minimumSize: const Size(0, 34),
            ),
            onPressed: () => _toggleVerify(
              doc,
              isVerified,
            ),
            icon: Icon(
              isVerified ? Icons.close : Icons.verified,
              size: 14,
            ),
            label: Text(
              isVerified ? 'Unverify' : 'Verify ✓',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Colors.redAccent,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            minimumSize: const Size(0, 34),
          ),
          onPressed: () => _delete(doc),
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 14,
          ),
          label: const Text(
            'Delete',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEventEditor(
    DocumentSnapshot<Map<String, dynamic>> eventDoc,
  ) async {
    final submission = await FirebaseFirestore.instance
        .collection('eventSubmissions')
        .doc(eventDoc.id)
        .get();

    if (!mounted) return;

    if (!submission.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Original event submission not found.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicSubmissionScreen(
          type: SubmissionType.event,
          editDocumentId: eventDoc.id,
        ),
      ),
    );
  }

  Future<void> _showEventDetails(
    DocumentSnapshot<Map<String, dynamic>> eventDoc,
  ) async {
    try {
      final submission = await FirebaseFirestore.instance
          .collection('eventSubmissions')
          .doc(eventDoc.id)
          .get();

      if (!mounted) return;

      final publicData = eventDoc.data() ?? <String, dynamic>{};
      final submissionData = submission.data() ?? <String, dynamic>{};

      final data = <String, dynamic>{
        ...publicData,
        ...submissionData,
      };

      final fields = data['fields'] is Map
          ? Map<String, dynamic>.from(data['fields'] as Map)
          : <String, dynamic>{};

      final eventDetails = data['eventDetails'] is Map
          ? Map<String, dynamic>.from(data['eventDetails'] as Map)
          : <String, dynamic>{};

      final publicTicketTypes = publicData['ticketTypes'];

      final ticketTypes =
          publicTicketTypes is List && publicTicketTypes.isNotEmpty
              ? publicTicketTypes
              : data['ticketTypes'] is List
                  ? data['ticketTypes'] as List
                  : const [];

      final artists =
          data['artists'] is List ? data['artists'] as List : const [];
      final photoUrls = <String>[];

      final rawEventMedia = data['eventMedia'] ?? data['media'];

      if (rawEventMedia is Map) {
        final media = Map<String, dynamic>.from(rawEventMedia);
        final rawPhotoUrls = media['photoUrls'];

        if (rawPhotoUrls is List) {
          photoUrls.addAll(
            rawPhotoUrls
                .map((url) => url.toString().trim())
                .where((url) => url.isNotEmpty),
          );
        }
      }

      final mainImageUrl =
          (data['imageUrl'] ?? data['image'])?.toString().trim() ?? '';

      if (mainImageUrl.isNotEmpty && !photoUrls.contains(mainImageUrl)) {
        photoUrls.insert(0, mainImageUrl);
      }
      final submittedInformation = <String, dynamic>{};

      fields.forEach((key, value) {
        if (value == null) return;

        if (value is String && value.trim().isEmpty) return;

        if (value is Map || value is List) return;

        submittedInformation[key] = value;
      });

      final title = _firstNonEmpty([
        fields['title'],
        data['title'],
        data['name'],
        'Event Details',
      ]);

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            initialChildSize: 0.94,
            minChildSize: 0.60,
            maxChildSize: 0.98,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF061E12),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        16,
                        8,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: primaryGold,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.white12,
                      height: 1,
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(18),
                        children: [
                          _eventAdminSection(
                            title: 'Event Information',
                            icon: Icons.event_outlined,
                            children: [
                              _eventAdminRow(
                                'Title',
                                fields['title'] ?? data['title'],
                              ),
                              _eventAdminRow(
                                'Description',
                                fields['description'] ?? data['description'],
                              ),
                              _eventAdminRow(
                                'Category',
                                fields['category'] ?? data['category'],
                              ),
                              _eventAdminRow(
                                'Country',
                                fields['country'] ?? data['country'],
                              ),
                              _eventAdminRow(
                                'Location',
                                fields['cityAddress'] ?? data['location'],
                              ),
                              _eventAdminRow(
                                'Address',
                                fields['address'] ?? data['address'],
                              ),
                              _eventAdminRow(
                                'Date',
                                fields['date'],
                              ),
                              _eventAdminRow(
                                'Start date',
                                fields['startDate'],
                              ),
                              _eventAdminRow(
                                'End date',
                                fields['endDate'],
                              ),
                              _eventAdminRow(
                                'Start time',
                                fields['startTime'] ?? fields['time'],
                              ),
                              _eventAdminRow(
                                'End time',
                                fields['endTime'],
                              ),
                            ],
                          ),
                          _eventAdminSection(
                            title: 'Organizer & Contact',
                            icon: Icons.person_outline,
                            children: [
                              _eventAdminRow(
                                'Organizer',
                                fields['organizerName'] ?? fields['organizer'],
                              ),
                              _eventAdminRow(
                                'Phone',
                                fields['phoneNumber'] ??
                                    fields['phone'] ??
                                    data['phone'],
                              ),
                              _eventAdminRow(
                                'Email',
                                fields['emailAddress'] ??
                                    fields['email'] ??
                                    data['email'] ??
                                    data['submitterEmail'],
                              ),
                              _eventAdminRow(
                                'Website',
                                fields['websiteUrl'] ??
                                    fields['website'] ??
                                    data['website'],
                              ),
                              _eventAdminRow(
                                'Submitted by',
                                data['submitterEmail'],
                              ),
                            ],
                          ),
                          if (eventDetails.isNotEmpty)
                            _eventAdminSection(
                              title: 'Event Options',
                              icon: Icons.tune,
                              children: [
                                _eventAdminBoolean(
                                  '18+ only',
                                  eventDetails['age18Only'] == true,
                                ),
                                _eventAdminBoolean(
                                  'Children allowed',
                                  eventDetails['kidsAllowed'] == true,
                                ),
                                _eventAdminBoolean(
                                  'Shisha available',
                                  eventDetails['shishaAvailable'] == true,
                                ),
                                _eventAdminBoolean(
                                  'Alcohol available',
                                  eventDetails['alcoholAvailable'] == true,
                                ),
                                _eventAdminBoolean(
                                  'Food available',
                                  eventDetails['foodAvailable'] == true,
                                ),
                                _eventAdminBoolean(
                                  'Non-refundable',
                                  data['nonRefundable'] == true ||
                                      eventDetails['nonRefundable'] == true,
                                ),
                                _eventAdminBoolean(
                                  'Non-transferable',
                                  data['nonTransferable'] == true ||
                                      eventDetails['nonTransferable'] == true,
                                ),
                              ],
                            ),
                          if (artists.isNotEmpty)
                            _eventAdminSection(
                              title: 'Artists / Performers',
                              icon: Icons.mic_external_on_outlined,
                              children: [
                                for (var index = 0;
                                    index < artists.length;
                                    index++)
                                  if (artists[index] is Map)
                                    _eventAdminArtist(
                                      Map<String, dynamic>.from(
                                        artists[index] as Map,
                                      ),
                                      index,
                                    ),
                              ],
                            ),
                          if (photoUrls.isNotEmpty)
                            _eventAdminSection(
                              title: 'Event Photos',
                              icon: Icons.photo_library_outlined,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final photoUrl in photoUrls)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          photoUrl,
                                          width: 95,
                                          height: 95,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return Container(
                                              width: 95,
                                              height: 95,
                                              alignment: Alignment.center,
                                              color: primaryDarkGreen,
                                              child: const Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.white38,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          if (ticketTypes.isNotEmpty)
                            _eventAdminSection(
                              title: 'Tickets & Capacity',
                              icon: Icons.confirmation_number_outlined,
                              children: [
                                for (var index = 0;
                                    index < ticketTypes.length;
                                    index++)
                                  if (ticketTypes[index] is Map)
                                    _eventAdminTicket(
                                      Map<String, dynamic>.from(
                                        ticketTypes[index] as Map,
                                      ),
                                      index,
                                    ),
                              ],
                            ),
                          if (submittedInformation.isNotEmpty)
                            _eventAdminSection(
                              title: 'All Submitted Information',
                              icon: Icons.list_alt_outlined,
                              children: [
                                for (final entry
                                    in submittedInformation.entries)
                                  _eventAdminRow(
                                    _eventAdminReadableFieldName(entry.key),
                                    entry.value,
                                  ),
                              ],
                            ),
                          _eventAdminSection(
                            title: 'Administration',
                            icon: Icons.admin_panel_settings_outlined,
                            children: [
                              _eventAdminRow(
                                'Status',
                                data['status'],
                              ),
                              _eventAdminRow(
                                'Event ID',
                                eventDoc.id,
                              ),
                              _eventAdminRow(
                                'Created',
                                data['createdAt'],
                              ),
                              _eventAdminRow(
                                'Published',
                                publicData['publishedAt'],
                              ),
                              _eventAdminRow(
                                'Updated',
                                data['updatedAt'],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGold,
                                foregroundColor: primaryDarkGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(sheetContext);
                                await _deleteEventSafely(eventDoc);
                              },
                              onLongPress: () async {
                                await _openEventEditor(
                                  eventDoc,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                              ),
                              label: const Text(
                                'Edit Event',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(sheetContext);

                                await _delete(eventDoc);
                              },
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                'Delete Event',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load event details: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _eventAdminSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  String _eventAdminReadableFieldName(String key) {
    final spaced = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .trim();

    if (spaced.isEmpty) return key;

    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  Widget _eventAdminRow(
    String label,
    dynamic value,
  ) {
    if (value == null) {
      return const SizedBox.shrink();
    }

    String displayedValue;

    if (value is Timestamp) {
      final date = value.toDate();

      displayedValue = '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } else if (value is bool) {
      displayedValue = value ? 'Yes' : 'No';
    } else {
      displayedValue = value.toString().trim();
    }

    if (displayedValue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayedValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventAdminBoolean(
    String label,
    bool value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel_outlined,
            color: value ? Colors.greenAccent : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value ? 'Yes' : 'No',
            style: TextStyle(
              color: value ? Colors.greenAccent : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventAdminTicket(
    Map<String, dynamic> ticket,
    int index,
  ) {
    final name = ticket['name']?.toString().trim().isNotEmpty == true
        ? ticket['name'].toString()
        : 'Ticket ${index + 1}';

    final price = double.tryParse(ticket['price']?.toString() ?? '') ?? 0;

    final capacity = int.tryParse(ticket['capacity']?.toString() ?? '') ?? 0;

    final sold = int.tryParse(ticket['sold']?.toString() ?? '') ?? 0;

    final remaining = capacity - sold < 0 ? 0 : capacity - sold;

    final active = ticket['active'] != false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryDarkGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                active ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: active ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price <= 0 ? 'Free' : '${price.toStringAsFixed(2)} €',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Capacity: $capacity • Sold: $sold • Remaining: $remaining',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventAdminArtist(
    Map<String, dynamic> artist,
    int index,
  ) {
    final name = artist['name']?.toString().trim().isNotEmpty == true
        ? artist['name'].toString()
        : 'Artist ${index + 1}';

    final photoUrl = artist['photoUrl']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryDarkGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const SizedBox(
                    width: 55,
                    height: 55,
                    child: Icon(
                      Icons.person,
                      color: Colors.white38,
                      size: 40,
                    ),
                  );
                },
              ),
            )
          else
            const SizedBox(
              width: 55,
              height: 55,
              child: Icon(
                Icons.person,
                color: Colors.white38,
                size: 40,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD / EDIT DIALOG
  // ---------------------------------------------------------------------------

  void _showAddEditDialog(
    DocumentSnapshot<Map<String, dynamic>>? existingDoc,
  ) {
    final isEditing = existingDoc != null;
    final data = existingDoc?.data() ?? <String, dynamic>{};

    final titleController = TextEditingController(
      text: _firstNonEmpty([
        data['title'],
        data['name'],
        data['text'],
        '',
      ]),
    );

    final locationController = TextEditingController(
      text: _firstNonEmpty([
        data['location'],
        data['address'],
        '',
      ]),
    );

    final descController = TextEditingController(
      text: _firstNonEmpty([
        data['description'],
        data['text'],
        '',
      ]),
    );

    final phoneController = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );

    final imageController = TextEditingController(
      text: _firstNonEmpty([
        data['imageUrl'],
        data['image'],
        data['logoUrl'],
        '',
      ]),
    );

    final categoryController = TextEditingController(
      text: _firstNonEmpty([
        data['category'],
        data['type'],
        data['businessCategory'],
        '',
      ]),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: cardGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing ? 'Edit Content' : 'Add New Content',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    'Title / Name *',
                    titleController,
                  ),
                  _dialogField(
                    'Category / Type',
                    categoryController,
                    hint: 'e.g. Restaurants, Concert, Service...',
                  ),
                  _dialogField(
                    'Location / City / Address',
                    locationController,
                  ),
                  _dialogField(
                    'Phone Number',
                    phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _dialogField(
                    'Image / Photo URL',
                    imageController,
                    hint: 'Paste image link or upload',
                  ),
                  _dialogField(
                    'Description / Details',
                    descController,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: primaryDarkGreen,
              ),
              onPressed: () async {
                final title = titleController.text.trim();

                if (title.isEmpty) {
                  if (!dialogCtx.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Title / Name is required.',
                      ),
                    ),
                  );
                  return;
                }

                final updateData = <String, dynamic>{
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

                try {
                  if (isEditing) {
                    await existingDoc.reference.set(
                      updateData,
                      SetOptions(merge: true),
                    );
                  } else {
                    updateData['createdAt'] = FieldValue.serverTimestamp();
                    updateData['publishedAt'] = FieldValue.serverTimestamp();
                    updateData['isDemo'] = false;

                    await FirebaseFirestore.instance
                        .collection(_selectedSection)
                        .add(updateData);
                  }

                  if (!dialogCtx.mounted) {
                    return;
                  }

                  Navigator.pop(dialogCtx);

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Content updated successfully.'
                            : 'New content published.',
                      ),
                      backgroundColor: cardGreen,
                    ),
                  );
                } catch (e) {
                  if (!dialogCtx.mounted) {
                    return;
                  }

                  Navigator.pop(dialogCtx);

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Operation failed: $e',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(
                isEditing ? 'Save Changes' : 'Publish',
                style: TextStyle(
                  color: primaryDarkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
          filled: true,
          fillColor: primaryDarkGreen,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VERIFY
  // ---------------------------------------------------------------------------

  Future<void> _toggleVerify(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool current,
  ) async {
    final next = !current;

    try {
      await doc.reference.update({
        'isVerified': next,
        'verificationStatus': next ? 'approved' : 'unverified',
        'verifiedAt': next ? FieldValue.serverTimestamp() : null,
        'verifiedBy': AppSession.email,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next ? 'Item verified successfully.' : 'Verification removed.',
          ),
          backgroundColor: cardGreen,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification update failed: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> _deleteEventSafely(
    DocumentSnapshot<Map<String, dynamic>> eventDoc,
  ) async {
    final eventId = eventDoc.id;

    try {
      final purchasedTickets = await FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .where('paymentStatus', isEqualTo: 'purchased')
          .limit(1)
          .get();

      if (!mounted) return;

      if (purchasedTickets.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('events').doc(eventId).set({
          'status': 'cancelled',
          'isActive': false,
          'isArchived': true,
          'cancelledAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('eventSubmissions')
            .doc(eventId)
            .set({
          'status': 'cancelled',
          'isActive': false,
          'isArchived': true,
          'cancelledAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        final publicFeedRef = FirebaseFirestore.instance
            .collection('publicFeed')
            .doc('eventSubmissions_$eventId');

        final publicFeedSnapshot = await publicFeedRef.get();

        if (publicFeedSnapshot.exists) {
          await publicFeedRef.set({
            'status': 'cancelled',
            'isActive': false,
            'isArchived': true,
            'cancelledAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Event archived because purchased tickets already exist.',
            ),
          ),
        );

        return;
      }

      await _deleteEventWithoutTickets(eventDoc);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete event: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteEventWithoutTickets(
    DocumentSnapshot<Map<String, dynamic>> eventDoc,
  ) async {
    final eventId = eventDoc.id;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: primaryDarkGreen,
          title: const Text(
            'Delete Event?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No purchased tickets were found. '
            'This event can be permanently deleted.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete Permanently',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    batch.delete(
      firestore.collection('events').doc(eventId),
    );

    batch.delete(
      firestore.collection('eventSubmissions').doc(eventId),
    );

    batch.delete(
      firestore.collection('publicFeed').doc('eventSubmissions_$eventId'),
    );

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event permanently deleted.'),
      ),
    );
  }

  Future<void> _delete(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Delete Content?',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This will permanently delete this item from the database.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final sourceCollection = doc.reference.parent.id;
      final sourceId = doc.id;

      final batch = firestore.batch();

      // Supprime le document original.
      batch.delete(doc.reference);

      // Format principal utilisé lors de la publication :
      // sourceCollection_documentId
      final publicFeedRef = firestore
          .collection('publicFeed')
          .doc('${sourceCollection}_$sourceId');

      batch.delete(publicFeedRef);

      await batch.commit();

      // Nettoyage de sécurité pour les anciens documents publicFeed
      // qui auraient été créés avec un autre identifiant.
      final oldFeedItems = await firestore
          .collection('publicFeed')
          .where('sourceCollection', isEqualTo: sourceCollection)
          .where('sourceId', isEqualTo: sourceId)
          .get();

      if (oldFeedItems.docs.isNotEmpty) {
        final cleanupBatch = firestore.batch();

        for (final feedDoc in oldFeedItems.docs) {
          cleanupBatch.delete(feedDoc.reference);
        }

        await cleanupBatch.commit();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item deleted from the database and public feed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}
