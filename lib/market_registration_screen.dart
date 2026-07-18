import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_localization_helper.dart';
import 'access_control.dart';
import 'moderation_state.dart';

class MarketRegistrationScreen extends StatefulWidget {
  const MarketRegistrationScreen({super.key});

  @override
  State<MarketRegistrationScreen> createState() => _MarketRegistrationScreenState();
}

class _MarketRegistrationScreenState extends State<MarketRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

  final TextEditingController _customSizeController = TextEditingController();
  final TextEditingController _dressLengthController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _shoulderWidthController = TextEditingController();
  final TextEditingController _sleeveLengthController = TextEditingController();

  final TextEditingController _dimensionWidthController = TextEditingController();
  final TextEditingController _dimensionHeightController = TextEditingController();
  final TextEditingController _dimensionDepthController = TextEditingController();
  final TextEditingController _technicalSpecsController = TextEditingController();

  static const List<String> _marketCategories = [
    'Clothing',
    'Traditional Attire',
    'Electronics',
    'TVs',
    'Home & Kitchen',
    'Beauty',
    'Services',
    'Vehicles',
    'Other',
  ];
  static const List<String> _standardSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Custom'];

  String _selectedCategory = 'Clothing';
  String _selectedStandardSize = 'M';
  bool _isSubmitting = false;

  bool get _isClothingOrTraditional {
    return _selectedCategory == 'Clothing' || _selectedCategory == 'Traditional Attire';
  }

  bool get _isTraditionalAttire {
    return _selectedCategory == 'Traditional Attire';
  }

  bool get _isElectronicsLike {
    return _selectedCategory == 'Electronics' || _selectedCategory == 'TVs';
  }

  String get _effectiveCategory {
    if (_selectedCategory != 'Other') return _selectedCategory;
    final custom = _customCategoryController.text.trim();
    return custom.isEmpty ? 'Other' : custom;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _customSizeController.dispose();
    _dressLengthController.dispose();
    _waistController.dispose();
    _shoulderWidthController.dispose();
    _sleeveLengthController.dispose();
    _dimensionWidthController.dispose();
    _dimensionHeightController.dispose();
    _dimensionDepthController.dispose();
    _technicalSpecsController.dispose();
    super.dispose();
  }

  bool _validateDynamicFields() {
    if (_selectedCategory == 'Other' && _customCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your custom category.')),
      );
      return false;
    }

    if (_isClothingOrTraditional && _selectedStandardSize == 'Custom' && _customSizeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide custom size details.')),
      );
      return false;
    }

    if (_isTraditionalAttire) {
      final requiredMeasurements = [
        _dressLengthController.text.trim(),
        _waistController.text.trim(),
        _shoulderWidthController.text.trim(),
        _sleeveLengthController.text.trim(),
      ];
      if (requiredMeasurements.any((value) => value.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all traditional attire measurements.')),
        );
        return false;
      }
    }

    if (_isElectronicsLike) {
      final hasDimension = _dimensionWidthController.text.trim().isNotEmpty
          || _dimensionHeightController.text.trim().isNotEmpty
          || _dimensionDepthController.text.trim().isNotEmpty;
      final hasSpecs = _technicalSpecsController.text.trim().isNotEmpty;
      if (!hasDimension && !hasSpecs) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add dimensions or technical specifications for electronics/TV listings.')),
        );
        return false;
      }
    }

    return true;
  }

  String _dynamicSummaryForConfirmation() {
    if (_isTraditionalAttire) {
      return 'Size: $_selectedStandardSize, Length: ${_dressLengthController.text.trim()} cm, '
          'Waist: ${_waistController.text.trim()} cm, Shoulder: ${_shoulderWidthController.text.trim()} cm, '
          'Sleeve: ${_sleeveLengthController.text.trim()} cm';
    }
    if (_isClothingOrTraditional) {
      final custom = _selectedStandardSize == 'Custom' ? ' (${_customSizeController.text.trim()})' : '';
      return 'Size: $_selectedStandardSize$custom';
    }
    if (_isElectronicsLike) {
      final width = _dimensionWidthController.text.trim();
      final height = _dimensionHeightController.text.trim();
      final depth = _dimensionDepthController.text.trim();
      final specs = _technicalSpecsController.text.trim();
      final dims = [width, height, depth].any((e) => e.isNotEmpty)
          ? 'Dimensions (W x H x D): ${width.isEmpty ? '-' : width} x ${height.isEmpty ? '-' : height} x ${depth.isEmpty ? '-' : depth}'
          : 'Dimensions: not provided';
      return specs.isEmpty ? dims : '$dims, Specs: $specs';
    }
    return 'Category details saved.';
  }

  Map<String, dynamic> _buildDynamicAttributes() {
    if (_isTraditionalAttire) {
      return {
        'size': _selectedStandardSize,
        'customSize': _customSizeController.text.trim(),
        'measurementsCm': {
          'length': _dressLengthController.text.trim(),
          'waist': _waistController.text.trim(),
          'shoulderWidth': _shoulderWidthController.text.trim(),
          'sleeveLength': _sleeveLengthController.text.trim(),
        },
      };
    }

    if (_isClothingOrTraditional) {
      return {
        'size': _selectedStandardSize,
        'customSize': _customSizeController.text.trim(),
      };
    }

    if (_isElectronicsLike) {
      return {
        'dimensionsCm': {
          'width': _dimensionWidthController.text.trim(),
          'height': _dimensionHeightController.text.trim(),
          'depth': _dimensionDepthController.text.trim(),
        },
        'technicalSpecs': _technicalSpecsController.text.trim(),
      };
    }

    return const <String, dynamic>{};
  }

  Future<void> _submitListing() async {
    if (!AccessControl.ensureApprovedContributor(context, actionLabel: tr('register_listing'))) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!_validateDynamicFields()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in before posting a marketplace listing.')),
        );
        return;
      }

      final title = _titleController.text.trim();
      final category = _effectiveCategory;
      final priceText = _priceController.text.trim();
      final parsedPrice = double.tryParse(priceText.replaceAll(',', '.'));
      final country = _countryController.text.trim();
      final phone = _phoneController.text.trim();
      final description = _descriptionController.text.trim();
      final dynamicAttributes = _buildDynamicAttributes();

      final searchableText = [
        title,
        category,
        country,
        description,
        dynamicAttributes.toString(),
      ].join(' ').toLowerCase();

      await FirebaseFirestore.instance.collection('market_submissions').add({
        'title': title,
        'category': category,
        'priceText': priceText,
        'priceValue': parsedPrice,
        'country': country,
        'phone': phone,
        'description': description,
        'dynamicAttributes': dynamicAttributes,
        'searchableText': searchableText,
        'userId': user.uid,
        'submittedBy': (user.email ?? 'unknown').trim(),
        'status': 'pending',
        'moderationStatus': 'pending',
        'adminReview': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ModerationState.addPendingContent(
        type: 'Marketplace',
        title: '$title ($category)',
        submittedBy: (user.email ?? 'unknown').trim(),
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listing submitted successfully. Status: Pending admin approval. ${_dynamicSummaryForConfirmation()}'),
          backgroundColor: Color(0xFF0E2E1E),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      final message = switch (error.code) {
        'permission-denied' => 'Marketplace submission blocked by Firestore rules. Please contact admin.',
        'unavailable' => 'Network unavailable. Please check internet and try again.',
        _ => error.message ?? error.code,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit listing: $error')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF0E2E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('sell_register_product')),
        actions: [AppLocalizationHelper.languageMenu(context)],
      ),
      backgroundColor: const Color(0xFF061E12),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('register_item_marketplace_info'),
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(tr('product_title')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('please_enter_listing_title');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration(tr('category')),
                dropdownColor: const Color(0xFF0E2E1E),
                style: const TextStyle(color: Colors.white),
                items: _marketCategories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                    if (!_isClothingOrTraditional) {
                      _selectedStandardSize = 'M';
                      _customSizeController.clear();
                      _dressLengthController.clear();
                      _waistController.clear();
                      _shoulderWidthController.clear();
                      _sleeveLengthController.clear();
                    }
                    if (!_isElectronicsLike) {
                      _dimensionWidthController.clear();
                      _dimensionHeightController.clear();
                      _dimensionDepthController.clear();
                      _technicalSpecsController.clear();
                    }
                  });
                },
              ),
              if (_selectedCategory == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customCategoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Custom category'),
                  validator: (value) {
                    if (_selectedCategory == 'Other' && (value == null || value.trim().isEmpty)) {
                      return tr('please_enter_product_category');
                    }
                    return null;
                  },
                ),
              ],
              if (_isClothingOrTraditional) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Size & Fit Details',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStandardSize,
                        decoration: _inputDecoration('Standard size'),
                        dropdownColor: const Color(0xFF0E2E1E),
                        style: const TextStyle(color: Colors.white),
                        items: _standardSizes
                            .map((size) => DropdownMenuItem<String>(
                                  value: size,
                                  child: Text(size),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedStandardSize = value;
                            if (value != 'Custom') {
                              _customSizeController.clear();
                            }
                          });
                        },
                      ),
                      if (_selectedStandardSize == 'Custom') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _customSizeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Custom size details (e.g. bust/chest/hips)'),
                        ),
                      ],
                      if (_isTraditionalAttire) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Traditional Attire Measurements',
                          style: TextStyle(color: Color(0xFFE8D79B), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _dressLengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Dress length (cm)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _waistController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Waist (cm)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _shoulderWidthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Shoulder width (cm)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _sleeveLengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Sleeve length (cm)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_isElectronicsLike) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Technical Details',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dimensionWidthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Width (cm, optional)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dimensionHeightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Height (cm, optional)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dimensionDepthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Depth (cm, optional)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _technicalSpecsController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _inputDecoration('Technical specifications (model, memory, condition, etc.)'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(tr('price')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('please_enter_price');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _countryController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(tr('country')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('please_enter_country');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(tr('contact_phone')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('please_enter_contact_phone');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: _inputDecoration(tr('description')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('please_describe_product_service');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submitListing,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061E12)),
                        ),
                      )
                    : Text(tr('register_listing'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
