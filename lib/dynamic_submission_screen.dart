import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_session.dart';

class DynamicSubmissionScreen extends StatefulWidget {
  final SubmissionType type;

  const DynamicSubmissionScreen({super.key, required this.type});

  @override
  State<DynamicSubmissionScreen> createState() => _DynamicSubmissionScreenState();
}

enum SubmissionType { business, event, community, job, verification }

class _DynamicSubmissionScreenState extends State<DynamicSubmissionScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final _formKey = GlobalKey<FormState>();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;
  bool _shishaAvailable = false;
  bool _kidsAllowed = false;
  bool _whatsappEnabled = true;
  bool _showExactAddress = false;
  String _selectedCountry = 'France';
  String _selectedJobCategory = 'Cleaning';
  String _translatorServiceType = 'In-person';
  String? _selectedVerificationTier;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _portfolioPhotos = [];
  final List<XFile> _workPhotos = [];
  final List<XFile> _cateringPhotos = [];
  final List<_MenuItemInput> _menuItems = [];

  final List<_EmbeddedBadgeTier> _badgeTiers = const [
    _EmbeddedBadgeTier(
      productId: 'silver_badge_yearly',
      title: 'Silver Badge',
      price: '€5 / year',
      description: 'Personal trust badge',
      icon: Icons.verified,
      color: Color(0xFFC0C0C0),
    ),
    _EmbeddedBadgeTier(
      productId: 'pro_badge_yearly',
      title: 'Pro Badge',
      price: '€10 / year',
      description: 'For businesses and professionals',
      icon: Icons.workspace_premium,
      color: Color(0xFF64B5F6),
    ),
    _EmbeddedBadgeTier(
      productId: 'vip_badge_yearly',
      title: 'VIP Badge',
      price: '€15 / year',
      description: 'Highest visibility tier',
      icon: Icons.diamond,
      color: Color(0xFFFFD700),
    ),
  ];

  final Map<String, String> _countryDialCodes = const {
    'France': '+33',
    'Belgium': '+32',
    'UK': '+44',
    'Netherlands': '+31',
    'Portugal': '+351',
    'Spain': '+34',
    'Italy': '+39',
    'Switzerland': '+41',
    'Finland': '+358',
    'Norway': '+47',
    'Sweden': '+46',
    'Denmark': '+45',
    'Germany': '+49',
    'Greece': '+30',
    'Poland': '+48',
    'Hungary': '+36',
    'Austria': '+43',
    'Bulgaria': '+359',
    'Romania': '+40',
    'Luxembourg': '+352',
    'Turkey': '+90',
  };

  final List<String> _jobCategories = const [
    'Cleaning',
    'Translator',
    'Fashion/Clothes Designer',
    'Catering / Food Seller (Injera & Wot)',
    'Taxi Driver',
    'Mechanic',
    'Electrician',
    'Furniture Assembly',
    'Plumber',
    'Photographer/Videographer',
    'Babysitting/Nanny',
    'Painter',
    'Moving/Transport (Truck)',
    'Airport Luggage Delivery',
    'Hairdresser/Barber',
    'Eyebrow/Beauty Services',
    'Makeup Artist',
    'Nail Technician',
    'Gardener',
    'Car Wash',
    'Tutoring/Language Teacher (e.g., Amharic, Tigrinya)',
  ];

  @override
  void initState() {
    super.initState();
    _controller('phoneNumber').text = '${_countryDialCodes[_selectedCountry]} ';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final item in _menuItems) {
      item.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) {
    return _controllers.putIfAbsent(key, () => TextEditingController());
  }

  String get _title {
    return switch (widget.type) {
      SubmissionType.business => 'Register a Business',
      SubmissionType.event => 'Submit an Event',
      SubmissionType.community => 'Register a Community',
      SubmissionType.job => 'Submit a Job or Service',
      SubmissionType.verification => 'Request Verification',
    };
  }

  String get _collectionName {
    return switch (widget.type) {
      SubmissionType.business => 'businessSubmissions',
      SubmissionType.event => 'eventSubmissions',
      SubmissionType.community => 'communitySubmissions',
      SubmissionType.job => 'jobSubmissions',
      SubmissionType.verification => 'verificationRequests',
    };
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSignInRequired('Please sign in before submitting for admin approval.');
      return;
    }

    if (AppSession.isGuest) {
      AppSession.signIn(
        name: user.displayName ?? user.email ?? 'Euro Habesha Member',
        emailAddress: user.email ?? '',
        verified: user.emailVerified,
      );
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (widget.type == SubmissionType.verification && _selectedVerificationTier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Silver, Pro, or VIP before continuing.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_selectedVerificationTier != null) {
        final iapStarted = await _startSelectedBadgePurchase();
        if (!iapStarted) {
          return;
        }
      }

      final data = <String, dynamic>{
        'type': widget.type.name,
        'status': 'pendingApproval',
        'submittedBy': user.uid,
        'ownerId': user.uid,
        'creatorId': user.uid,
        'submitterEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'fields': {
          ..._controllers.map((key, controller) => MapEntry(key, controller.text.trim())),
          'country': _selectedCountry,
          'showExactAddress': _showExactAddress,
          if (_selectedVerificationTier != null) 'verificationBadgeProductId': _selectedVerificationTier,
          if (widget.type == SubmissionType.job) ...{
            'jobCategory': _selectedJobCategory,
            'translatorServiceType': _translatorServiceType,
          },
        },
        if (_selectedVerificationTier != null) 'verificationBadge': _selectedBadgeTierMap(),
      };

      if (widget.type == SubmissionType.business) {
        data['contactModel'] = {
          'inAppMessagingEnabled': false,
          'primaryAction': 'callForReservation',
          'reservePlusReady': true,
          'liveZoneReady': true,
        };
      }

      if (widget.type == SubmissionType.job) {
        data['contactModel'] = {
          'inAppMessagingEnabled': true,
          'whatsappEnabled': _whatsappEnabled,
        };
        data['media'] = {
          'portfolioPhotoPaths': _portfolioPhotos.map((file) => file.path).toList(),
          'workPhotoPaths': _workPhotos.map((file) => file.path).toList(),
          'cateringPhotoPaths': _cateringPhotos.map((file) => file.path).toList(),
        };
        data['menuItems'] = _menuItems.map((item) => item.toMap()).toList();
        data['orderingModel'] = {
          'cashOnDeliveryOnly': _selectedJobCategory == 'Catering / Food Seller (Injera & Wot)' || _selectedJobCategory == 'Fashion/Clothes Designer',
          'paymentMethod': 'cashOnDelivery',
        };
      }

      if (widget.type == SubmissionType.event) {
        data['eventDetails'] = {
          'kidsAllowed': _kidsAllowed,
          'shishaAvailable': _shishaAvailable,
          'visualBadges': ['performer', 'endTime', 'ageRestriction', if (_shishaAvailable) 'shisha'],
        };
      }

      await FirebaseFirestore.instance.collection(_collectionName).add(data);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for admin approval.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _startSelectedBadgePurchase() async {
    final productId = _selectedVerificationTier;
    if (productId == null) {
      return true;
    }

    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store billing is not available on this device yet.')),
        );
      }
      return false;
    }

    final response = await _inAppPurchase.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected badge product is not configured in Google Play / App Store yet.')),
        );
      }
      return false;
    }

    return _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
    );
  }

  Map<String, String>? _selectedBadgeTierMap() {
    final productId = _selectedVerificationTier;
    if (productId == null) {
      return null;
    }
    final tier = _badgeTiers.firstWhere((item) => item.productId == productId);
    return {
      'productId': tier.productId,
      'title': tier.title,
      'price': tier.price,
      'status': 'iapStarted',
    };
  }

  void _showSignInRequired(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text('Account Required', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Sign In / Register', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
          children: [
            _buildCommonFields(),
            const SizedBox(height: 12),
            ..._buildTypeFields(),
            const SizedBox(height: 16),
            _buildEmbeddedVerificationTiers(),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold, padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit for Approval', style: const TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        _buildField('title', 'Title / Name *'),
        const SizedBox(height: 12),
        _buildCountryDropdown(),
        const SizedBox(height: 12),
        _buildField('phoneNumber', 'Phone Number *'),
        const SizedBox(height: 12),
        _buildField('cityAddress', 'City & Address *'),
        const SizedBox(height: 12),
        _buildField('description', 'Description *', maxLines: 5),
      ],
    );
  }

  List<Widget> _buildTypeFields() {
    return switch (widget.type) {
      SubmissionType.event => [
          _buildField('performerDj', 'Performer / DJ name'),
          const SizedBox(height: 12),
          _buildField('startTime', 'Event start time'),
          const SizedBox(height: 12),
          _buildField('endTime', 'Event end time'),
          const SizedBox(height: 12),
          _buildField('ageRestriction', 'Age restriction, e.g. 18+ only'),
          _buildSwitch('Kids allowed', _kidsAllowed, (value) => setState(() => _kidsAllowed = value)),
          _buildSwitch('Shisha available', _shishaAvailable, (value) => setState(() => _shishaAvailable = value)),
          _buildField('amenities', 'Amenities, e.g. parking, VIP, food', maxLines: 3),
        ],
      SubmissionType.community => [
          _buildField('communityType', 'Community type, e.g. Orthodox Church, Mosque'),
          const SizedBox(height: 12),
          _buildField('meetingSchedule', 'Service / gathering schedule'),
          const SizedBox(height: 12),
          _buildField('leaderName', 'Leader or contact person'),
          const SizedBox(height: 12),
          _buildField('address', 'Full address'),
        ],
      SubmissionType.job => [
          _buildJobCategoryDropdown(),
          const SizedBox(height: 12),
          ..._buildJobSpecificFields(),
          const SizedBox(height: 12),
          _buildSwitch('Allow WhatsApp contact using this phone number', _whatsappEnabled, (value) => setState(() => _whatsappEnabled = value)),
          _buildSwitch('Show exact address publicly', _showExactAddress, (value) => setState(() => _showExactAddress = value)),
          _buildField('cityOnlyLocation', 'City shown publicly, e.g. Lyon', maxLines: 1),
          const SizedBox(height: 12),
          _buildField('requirements', 'Requirements / service details', maxLines: 3),
        ],
      SubmissionType.business => [
          _buildField('businessCategory', 'Business category'),
          const SizedBox(height: 12),
          _buildField('openingHours', 'Opening hours'),
          const SizedBox(height: 12),
          _buildField('address', 'Full address'),
          const SizedBox(height: 8),
          const Text('Business profiles use Call for Reservation only. In-app messaging is disabled. Reserve Plus and Live Zone fields are reserved for future release.', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
        ],
      SubmissionType.verification => [
          _buildField('verificationType', 'Verification type'),
          const SizedBox(height: 12),
          _buildField('documentSummary', 'Document or proof summary', maxLines: 3),
          const SizedBox(height: 12),
          _buildField('publicProfileLink', 'Website or profile link'),
        ],
    };
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      isExpanded: true,
      dropdownColor: cardGreen,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Country *',
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      selectedItemBuilder: (context) => _countryDialCodes.keys.map((country) => Text(country, overflow: TextOverflow.ellipsis)).toList(),
      items: _countryDialCodes.keys.map((country) => DropdownMenuItem<String>(value: country, child: Text(country, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (country) {
        if (country == null) return;
        setState(() {
          _selectedCountry = country;
          _controller('phoneNumber').text = '${_countryDialCodes[country]} ';
        });
      },
    );
  }

  Widget _buildJobCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedJobCategory,
      isExpanded: true,
      dropdownColor: cardGreen,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Job Category / Profession *',
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      selectedItemBuilder: (context) => _jobCategories.map((category) => Text(category, overflow: TextOverflow.ellipsis)).toList(),
      items: _jobCategories.map((category) => DropdownMenuItem<String>(value: category, child: Text(category, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (category) {
        if (category == null) return;
        setState(() {
          _selectedJobCategory = category;
          if (_selectedJobCategory == 'Catering / Food Seller (Injera & Wot)' && _menuItems.isEmpty) {
            _menuItems.add(_MenuItemInput());
          }
        });
      },
    );
  }

  List<Widget> _buildJobSpecificFields() {
    if (_selectedJobCategory == 'Translator') {
      return [
        _buildDropdown(
          label: 'Service Type *',
          value: _translatorServiceType,
          values: const ['In-person', 'Phone'],
          onChanged: (value) => setState(() => _translatorServiceType = value),
        ),
        const SizedBox(height: 12),
        _buildField('ratePerHour', 'Rate per hour'),
        const SizedBox(height: 12),
        _buildField('ratePerDocument', 'Rate per document / paper'),
        const SizedBox(height: 12),
        _buildField('websiteUrl', 'Website URL (optional)'),
      ];
    }

    if (_selectedJobCategory == 'Fashion/Clothes Designer') {
      return [
        _buildPhotoPicker('Portfolio photos', _portfolioPhotos, 5),
        const SizedBox(height: 12),
        _buildField('designerSpecialty', 'Designer specialty'),
        const SizedBox(height: 12),
        _buildField('orderMeasurements', 'Order/Command Form: height, size, chest, waist, hips, sleeve, notes', maxLines: 5),
        const SizedBox(height: 12),
        const Text('Client orders for designer clothes are cash on delivery / pay on arrival only.', style: TextStyle(color: Colors.white60, fontSize: 12)),
      ];
    }

    if (_selectedJobCategory == 'Catering / Food Seller (Injera & Wot)') {
      return [
        _buildPhotoPicker('Catering photos', _cateringPhotos, 10),
        const SizedBox(height: 12),
        _buildMenuBuilder(),
        const SizedBox(height: 12),
        const Text('Food orders are cash on delivery / pay on arrival only.', style: TextStyle(color: Colors.white60, fontSize: 12)),
      ];
    }

    return [
      _buildField('payRange', 'Pay range'),
      const SizedBox(height: 12),
      _buildPhotoPicker('Previous work photos', _workPhotos, 3),
      const SizedBox(height: 12),
      _buildField('exactAddressOptional', 'Exact address (optional)'),
    ];
  }

  Widget _buildDropdown({required String label, required String value, required List<String> values, required ValueChanged<String> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: cardGreen,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      selectedItemBuilder: (context) => values.map((item) => Text(item, overflow: TextOverflow.ellipsis)).toList(),
      items: values.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }

  Widget _buildEmbeddedVerificationTiers() {
    final required = widget.type == SubmissionType.verification;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: required && _selectedVerificationTier == null ? Colors.orangeAccent : primaryGold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: primaryGold, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Verification Badge Tier', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            required ? 'Required for verification requests.' : 'Optional: add a yearly trust badge to this submission.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final tier in _badgeTiers) _buildBadgeTierRadio(tier),
          if (!required && _selectedVerificationTier != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _selectedVerificationTier = null),
                child: const Text('No badge for now'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeTierRadio(_EmbeddedBadgeTier tier) {
    final selected = _selectedVerificationTier == tier.productId;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedVerificationTier = tier.productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? tier.color : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(tier.icon, color: tier.color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier.title, style: TextStyle(color: tier.color, fontWeight: FontWeight.bold)),
                  Text(tier.description, style: const TextStyle(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(tier.price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Radio<String>(
                  value: tier.productId,
                  groupValue: _selectedVerificationTier,
                  activeColor: tier.color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) => setState(() => _selectedVerificationTier = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(String label, List<XFile> files, int maxCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label (${files.length}/$maxCount)', style: const TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in files)
                Chip(
                  label: Text(file.name, overflow: TextOverflow.ellipsis),
                  onDeleted: () => setState(() => files.remove(file)),
                ),
              if (files.length < maxCount)
                ActionChip(
                  avatar: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Add photo'),
                  onPressed: () async {
                    final picked = await _picker.pickMultiImage(limit: maxCount - files.length);
                    if (picked.isEmpty) return;
                    setState(() => files.addAll(picked.take(maxCount - files.length)));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBuilder() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Dynamic Menu Builder', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold))),
              IconButton(
                onPressed: () => setState(() => _menuItems.add(_MenuItemInput())),
                icon: const Icon(Icons.add_circle, color: primaryGold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: _buildInlineField('Item', item.nameController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 96, child: _buildInlineField('Price', item.priceController, keyboardType: TextInputType.number)),
                    IconButton(
                      onPressed: _menuItems.length == 1 ? null : () => setState(() => _menuItems.removeAt(index)),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInlineField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: primaryDarkGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildField(String key, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: _controller(key),
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: label.endsWith('*') ? (value) => value == null || value.trim().isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: primaryGold,
      title: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _MenuItemInput {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'name': nameController.text.trim(),
      'price': priceController.text.trim(),
    };
  }
}

class _EmbeddedBadgeTier {
  final String productId;
  final String title;
  final String price;
  final String description;
  final IconData icon;
  final Color color;

  const _EmbeddedBadgeTier({
    required this.productId,
    required this.title,
    required this.price,
    required this.description,
    required this.icon,
    required this.color,
  });
}
