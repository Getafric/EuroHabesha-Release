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

enum SubmissionType { business, professional, event, community, job, verification, marketplace }

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
  bool _nonRefundable = false;
  bool _nonTransferable = false;
  String _selectedCountry = 'France';
  String _selectedJobCategory = 'Cleaning';
  String _translatorServiceType = 'In-person';
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _portfolioPhotos = [];
  final List<XFile> _workPhotos = [];
  final List<XFile> _cateringPhotos = [];
  final List<_MenuItemInput> _menuItems = [];

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
      SubmissionType.business => 'Register a Business / Restaurant',
      SubmissionType.professional => 'Register as a Professional',
      SubmissionType.event => 'Submit an Event',
      SubmissionType.community => 'Register a Community',
      SubmissionType.job => 'Submit a Job or Service',
      SubmissionType.verification => 'Request Verification',
      SubmissionType.marketplace => 'Post Marketplace Item',
    };
  }

  String get _collectionName {
    return switch (widget.type) {
      SubmissionType.business => 'businessSubmissions',
      SubmissionType.professional => 'jobSubmissions',
      SubmissionType.event => 'eventSubmissions',
      SubmissionType.community => 'communitySubmissions',
      SubmissionType.job => 'jobSubmissions',
      SubmissionType.verification => 'verificationRequests',
      SubmissionType.marketplace => 'marketplaceSubmissions',
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

    setState(() => _isSubmitting = true);
    try {
      final data = <String, dynamic>{
        'type': widget.type.name,
        'status': 'pendingApproval',
        'isVerified': false,
        'submittedBy': user.uid,
        'ownerId': user.uid,
        'creatorId': user.uid,
        'submitterEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'fields': {
          ..._controllers.map((key, controller) => MapEntry(key, controller.text.trim())),
          'country': _selectedCountry,
          'showExactAddress': _showExactAddress,
          if (widget.type == SubmissionType.job) ...{
            'jobCategory': _selectedJobCategory,
            'translatorServiceType': _translatorServiceType,
          },
        },
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
          'cashOnDeliveryOnly': _selectedJobCategory == 'Fashion/Clothes Designer',
          'depositPercentage': double.tryParse(_controller('depositPercentage').text.trim()) ?? 0,
          'paymentMethods': ['cashOnDelivery', 'appDeposit'],
        };
      }

      if (widget.type == SubmissionType.event) {
        data['eventDetails'] = {
          'kidsAllowed': _kidsAllowed,
          'shishaAvailable': _shishaAvailable,
          'nonRefundable': _nonRefundable,
          'nonTransferable': _nonTransferable,
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
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold, padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit for Admin Approval', style: const TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
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
          _buildSwitch('Tickets are non-refundable', _nonRefundable, (value) => setState(() => _nonRefundable = value)),
          _buildSwitch('Tickets are non-transferable', _nonTransferable, (value) => setState(() => _nonTransferable = value)),
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
      SubmissionType.professional => [
          _buildField('professionTitle', 'Professional Title (Doctor, Lawyer, Translator, Caterer, etc.) *'),
          const SizedBox(height: 12),
          _buildField('registrationNumber', 'SIRET / Professional License / Registration ID'),
          const SizedBox(height: 12),
          _buildField('servicesOffered', 'Services Offered (list services, one per line) *', maxLines: 3),
          const SizedBox(height: 12),
          _buildField('pricingDetails', 'Pricing & Rates (e.g. €25/hour, from €30/doc, menu prices) *', maxLines: 3),
          const SizedBox(height: 12),
          _buildField('qualifications', 'Qualifications, Diplomas & Experience', maxLines: 3),
          const SizedBox(height: 12),
          _buildField('websiteUrl', 'Website, LinkedIn or Portfolio URL (optional)'),
          const SizedBox(height: 12),
          _buildSwitch('Allow WhatsApp contact using this phone number', _whatsappEnabled, (value) => setState(() => _whatsappEnabled = value)),
          _buildSwitch('Show exact address publicly', _showExactAddress, (value) => setState(() => _showExactAddress = value)),
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
      SubmissionType.marketplace => [
          _buildField('itemCategory', 'Category (Vehicles, Electronics, Clothing, Habesha, etc.) *'),
          const SizedBox(height: 12),
          _buildField('price', 'Price (€) *'),
          const SizedBox(height: 12),
          _buildField('condition', 'Item Condition (New, Used - Like New, Used - Good) *'),
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
        _buildField('depositPercentage', 'Deposit percentage (0-100, optional)', keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        const Text('Customers can contact you directly or request an in-app deposit. The deposit is calculated from the order total.', style: TextStyle(color: Colors.white60, fontSize: 12)),
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

  Widget _buildField(
    String key,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: _controller(key),
      maxLines: maxLines,
      keyboardType: keyboardType,
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
