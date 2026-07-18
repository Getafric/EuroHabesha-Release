import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_localization_helper.dart';
import 'access_control.dart';
import 'provider_chat_thread_screen.dart';
import 'registration_screen.dart';
import 'service_profile_detail_screen.dart';
import 'session_state.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({
    super.key,
    this.initialCategory,
    this.showSubmissionOnly = false,
    this.searchOnly = false,
  });

  final String? initialCategory;
  final bool showSubmissionOnly;
  final bool searchOnly;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const String _photoPack5Id = 'photo_pack_5_eur';
  static const String _photoPack10Id = 'photo_pack_10_eur';

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final TextEditingController _providerNameController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final TextEditingController _cityZipController = TextEditingController();
  final TextEditingController _localPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _governmentRegistrationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _browseQueryController = TextEditingController();

  final List<String> _jobCategories = [
    'Cleaning Services',
    'Mechanics',
    'Business Services',
    'Car Wash',
    'Photography & Videography',
    'DJ Services',
    'Electrician',
    'Painting',
    'Furniture Assembly / Carpentry',
    'Gardening',
    'Catering Services',
    'Decor Services',
    'Medical Professionals (Doctors / Pharmacists)',
    'Legal Counsel',
    'Translators',
    'Taxi / Truck Drivers',
    'Airport Pickup / Logistics',
    'Miscellaneous / Other',
  ];

  final Map<String, String> _countryDialCodes = {
    'Germany': '+49',
    'France': '+33',
    'United Kingdom': '+44',
    'United States': '+1',
    'Canada': '+1',
    'Italy': '+39',
    'Spain': '+34',
    'Netherlands': '+31',
    'Belgium': '+32',
    'Austria': '+43',
    'Switzerland': '+41',
  };

  String _selectedCategory = '';
  String _selectedListingType = 'Professional';
  String _selectedCountry = 'Germany';
  String _selectedDialCode = '+49';
  List<XFile> _pickedImages = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _storeReady = false;
  bool _isPurchaseInProgress = false;
  bool _isSubmittingListing = false;
  int _photoLimit = 5;
  String _browseQuery = '';
  String _browseCategoryFilter = 'All';

  bool get _hasAuthUser => FirebaseAuth.instance.currentUser != null;

  void _syncSessionFromAuth() {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    if (!SessionState.isGuest && SessionState.isVerified) return;

    final contact = (authUser.email ?? authUser.uid).trim();
    SessionState.markVerified(
      contact,
      approved: true,
      uid: authUser.uid,
      name: (authUser.displayName ?? '').trim().isEmpty ? null : authUser.displayName,
    );
  }

  Future<void> _refreshJobsPage() async {
    await _initStore();
    if (!mounted) return;
    setState(() {});
  }

  bool get _isPaidPhotoCategory =>
      _selectedCategory == 'Catering Services' || _selectedCategory == 'Decor Services';

  int get _currentPhotoLimit => _isPaidPhotoCategory ? _photoLimit : 5;

  @override
  void initState() {
    super.initState();
    _syncSessionFromAuth();
    _selectedCategory = widget.initialCategory != null && _jobCategories.contains(widget.initialCategory)
        ? widget.initialCategory!
        : _jobCategories.first;
    _selectedCountry = _countryDialCodes.keys.first;
    _selectedDialCode = _countryDialCodes[_selectedCountry]!;
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isPurchaseInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase stream error: $error')),
        );
      },
    );
    _initStore();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _providerNameController.dispose();
    _customCategoryController.dispose();
    _cityZipController.dispose();
    _localPhoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _governmentRegistrationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _browseQueryController.dispose();
    super.dispose();
  }

  Future<void> _initStore() async {
    final available = await _inAppPurchase.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _storeReady = false;
      });
      return;
    }

    const productIds = <String>{_photoPack5Id, _photoPack10Id};
    final response = await _inAppPurchase.queryProductDetails(productIds);
    if (!mounted) return;
    setState(() {
      _storeReady = true;
      _products = response.productDetails;
    });
  }

  ProductDetails? _productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  String _displayPrice(String productId, String fallback) {
    final product = _productById(productId);
    if (product == null) return fallback;
    return product.price;
  }

  Future<void> _buyPhotoPack(String productId) async {
    if (!_storeReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store is not available right now. Please try again later.')),
      );
      return;
    }

    final product = _productById(productId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found in store. Check product IDs in App Store / Play Console.')),
      );
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    setState(() {
      _isPurchaseInProgress = true;
    });
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdated(List<PurchaseDetails> detailsList) {
    for (final purchase in detailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() {
            _isPurchaseInProgress = true;
          });
        }
      }

      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() {
            _isPurchaseInProgress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${purchase.error?.message ?? 'Unknown error'}')),
          );
        }
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        var unlocked = 5;
        if (purchase.productID == _photoPack5Id) {
          unlocked = 10;
        } else if (purchase.productID == _photoPack10Id) {
          unlocked = 15;
        }

        if (mounted) {
          setState(() {
            if (unlocked > _photoLimit) {
              _photoLimit = unlocked;
            }
            _isPurchaseInProgress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment completed. You can now upload up to $_photoLimit photos.')),
          );
        }
      }

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );

    final limit = _currentPhotoLimit;

    setState(() {
      _pickedImages = images.take(limit).toList();
      if (images.length > limit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only the first $limit photos were saved.'),
          ),
        );
      }
    });
  }

  void _handleCategoryChange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedCategory = value;
      if (_selectedCategory != 'Miscellaneous / Other') {
        _customCategoryController.clear();
      }
      if (!_isPaidPhotoCategory) {
        _photoLimit = 5;
      }
      if (_pickedImages.length > _currentPhotoLimit) {
        _pickedImages = _pickedImages.take(_currentPhotoLimit).toList();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tr('professional_ethics_prefix')} ${_selectedCategory == 'Miscellaneous / Other' ? tr('custom_service') : _selectedCategory}',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleCountryChange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedCountry = value;
      _selectedDialCode = _countryDialCodes[value]!;
    });
  }

  bool _isBrowseCategoryMatch(String selectedCategory, String dataCategory) {
    String normalize(String input) {
      return input
          .toLowerCase()
          .replaceAll('&', ' and ')
          .replaceAll('/', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final selected = normalize(selectedCategory);
    final current = normalize(dataCategory);
    if (selected == current) return true;
    return current.contains(selected) || selected.contains(current);
  }

  void _openCategoryPage(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobCategoryPage(category: category)),
    );
  }

  Future<void> _submitJobListing() async {
    if (_isSubmittingListing) return;
    if (!AccessControl.ensureApprovedContributor(context, actionLabel: tr('publish_job_listing'))) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmittingListing = true;
    });

    final category = _selectedCategory == 'Miscellaneous / Other'
        ? _customCategoryController.text.trim()
        : _selectedCategory;
    final phone = '$_selectedDialCode ${_localPhoneController.text.trim()}';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final submittedBy = (FirebaseAuth.instance.currentUser?.email ?? 'unknown').trim();
    final providerName = _providerNameController.text.trim();
    final listingType = _selectedListingType.trim();
    final cityText = _cityZipController.text.trim();
    final email = _emailController.text.trim();
    final rawWebsite = _websiteController.text.trim();
    final website = rawWebsite.isEmpty
      ? ''
      : (rawWebsite.startsWith('http://') || rawWebsite.startsWith('https://') ? rawWebsite : 'https://$rawWebsite');
    final governmentRegistrationNumber = _governmentRegistrationController.text.trim();
    final description = _descriptionController.text.trim();
    final parsedPrice = double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0;

    try {
      await FirebaseFirestore.instance.collection('job_submissions').add({
        'title': providerName.isEmpty ? category : '$providerName - $category',
        'providerName': providerName,
        'listingType': listingType,
        'category': category,
        'country': _selectedCountry,
        'city': cityText,
        'phone': phone,
        'email': email,
        'website': website,
        'governmentRegistrationNumber': governmentRegistrationNumber,
        'description': description,
        'price': parsedPrice,
        'userId': uid,
        'submittedBy': submittedBy,
        'status': 'pending',
        'moderationStatus': 'pending',
        'adminReview': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isSubmittingListing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission timed out. Please check internet connection and try again.')),
      );
      return;
    } on FirebaseException catch (error) {
      final message = switch (error.code) {
        'permission-denied' => 'Submission blocked by Firestore rules. Please ask admin to allow job submissions.',
        'unavailable' => 'No internet connection. Please try again.',
        _ => error.message ?? error.code,
      };
      if (!mounted) return;
      setState(() {
        _isSubmittingListing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmittingListing = false;
    });
    _formKey.currentState?.reset();
    _providerNameController.clear();
    _customCategoryController.clear();
    _selectedListingType = 'Professional';
    _cityZipController.clear();
    _localPhoneController.clear();
    _emailController.clear();
    _websiteController.clear();
    _governmentRegistrationController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _pickedImages = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tr('listing_created_for')} $category. ${tr('contact')}: $phone. Submitted for admin approval.'),
      ),
    );
  }

  Widget _buildBrowsePublicJobs() {
    final hasAccount = _hasAuthUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                'Browse Jobs Without Registration',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                hasAccount
                    ? 'You are signed in. Use Post Job to publish your listing.'
                    : 'Anyone can browse jobs. Create an account to post your own listing, apply faster, and build a trusted profile.',
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 10),
              if (!hasAccount)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    foregroundColor: const Color(0xFFF59E0B),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create Account'),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobsScreen(
                          initialCategory: _selectedCategory,
                          showSubmissionOnly: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.post_add_outlined),
                  label: const Text('Post Job'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _browseQueryController,
          onChanged: (value) {
            setState(() {
              _browseQuery = value;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Search jobs/services').copyWith(
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('status', isEqualTo: 'approved')
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final categories = <String>{'All'};
            for (final doc in docs) {
              final category = (doc.data()['category'] ?? '').toString().trim();
              if (category.isNotEmpty) categories.add(category);
            }

            if (!categories.contains(_browseCategoryFilter)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _browseCategoryFilter = 'All';
                });
              });
            }

            final filteredDocs = docs.where((doc) {
              final data = doc.data();
              final category = (data['category'] ?? '').toString();
              final title = (data['title'] ?? '').toString();
              final city = (data['city'] ?? '').toString();
              final country = (data['country'] ?? '').toString();

              final matchCategory = _browseCategoryFilter == 'All'
                  ? true
                  : _isBrowseCategoryMatch(_browseCategoryFilter, category) || category == _browseCategoryFilter;

              final query = _browseQuery.trim().toLowerCase();
              final haystack = '$title $category $city $country'.toLowerCase();
              final matchQuery = query.isEmpty || haystack.contains(query);

              return matchCategory && matchQuery;
            }).toList();

            if (docs.isEmpty) {
              return const Text(
                'No approved jobs yet. Be the first to submit one.',
                style: TextStyle(color: Colors.white54),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _browseCategoryFilter,
                  decoration: _buildInputDecoration('Filter by category'),
                  dropdownColor: const Color(0xFF0E2E1E),
                  style: const TextStyle(color: Colors.white),
                  items: categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _browseCategoryFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (filteredDocs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No jobs match this search/filter.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  Column(
                    children: filteredDocs.map((doc) {
                      final data = doc.data();
                      final title = (data['title'] ?? 'Job listing').toString();
                      final city = (data['city'] ?? '').toString();
                      final country = (data['country'] ?? '').toString();
                      final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0;
                      final rateText = price > 0 ? '€${price.toStringAsFixed(0)}/hr' : 'Negotiable';

                      return Card(
                        color: const Color(0xFF0E2E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        child: ListTile(
                          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('$city, $country', style: const TextStyle(color: Colors.white60)),
                          trailing: Text(rateText, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryBrowser() {
    return _buildFormSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse Service Categories',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open any category to search services, view provider profiles, and contact providers when you are ready.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _jobCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final category = _jobCategories[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCategoryPage(category),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFF123222),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x33F59E0B)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0x22F59E0B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_iconForServiceCategory(category), color: const Color(0xFFF59E0B)),
                          ),
                          Text(
                            category,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.25),
                          ),
                          const Text(
                            'Open category',
                            style: TextStyle(color: Color(0xFFE8D79B), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEthicsBanner() {
    final categoryLabel = _selectedCategory == 'Miscellaneous / Other' ? tr('custom_service') : _selectedCategory;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111F18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('professional_ethics'),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${tr('you_selected')} $categoryLabel. ${tr('ethics_detail')}',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr('listing_photos'),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library, color: Color(0xFFF59E0B), size: 18),
              label: Text(
                'Pick up to $_currentPhotoLimit images',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Color(0xFFF59E0B)),
              ),
            ),
          ],
        ),
        if (_isPaidPhotoCategory) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catering/Decor photo plan: $_currentPhotoLimit photos unlocked',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Free: 5 photos. Upgrade after payment: +5 photos (EUR 2) or +10 photos (EUR 4).',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                        onPressed: (_isPurchaseInProgress || _photoLimit >= 10)
                          ? null
                          : () => _buyPhotoPack(_photoPack5Id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF061E12),
                      ),
                      child: Text('Unlock +5 photos (${_displayPrice(_photoPack5Id, 'EUR 2.00')})'),
                    ),
                    ElevatedButton(
                      onPressed: (_isPurchaseInProgress || _photoLimit >= 15)
                          ? null
                          : () => _buyPhotoPack(_photoPack10Id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF061E12),
                      ),
                      child: Text('Unlock +10 photos (${_displayPrice(_photoPack10Id, 'EUR 4.00')})'),
                    ),
                  ],
                ),
                if (!_storeReady)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Store is currently unavailable. Check App Store / Play billing setup.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                if (_isPurchaseInProgress)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Payment in progress... waiting for transaction confirmation.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (_pickedImages.isEmpty)
          Text(tr('no_photos_selected'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
        if (_pickedImages.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _pickedImages.map((file) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(file.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFF0E2E1E),
                    child: const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formCard = _buildFormSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('create_listing'),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            tr('select_category_location_detail'),
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _selectedListingType,
            decoration: _buildInputDecoration('Profile type'),
            dropdownColor: const Color(0xFF0E2E1E),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Professional', child: Text('Professional')),
              DropdownMenuItem(value: 'Business', child: Text('Business')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedListingType = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            isExpanded: true,
            decoration: _buildInputDecoration(tr('select_category')),
            items: _jobCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return _jobCategories.map((category) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            onChanged: _handleCategoryChange,
          ),
          if (_selectedCategory == 'Miscellaneous / Other') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customCategoryController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration(tr('enter_custom_skill')),
              validator: (value) {
                if (_selectedCategory == 'Miscellaneous / Other' && (value == null || value.trim().isEmpty)) {
                  return tr('please_describe_custom_service');
                }
                return null;
              },
            ),
          ],
          _buildEthicsBanner(),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedCountry,
            isExpanded: true,
            decoration: _buildInputDecoration(tr('country')),
            items: _countryDialCodes.keys.map((country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(
                  country,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _handleCountryChange,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cityZipController,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration(tr('city_or_postal_code')),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr('please_enter_city_or_postal');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _localPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration(tr('phone_number')).copyWith(
              prefixText: '$_selectedDialCode ',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr('please_enter_phone_number');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Email (optional)'),
            validator: (value) {
              final input = (value ?? '').trim();
              if (input.isEmpty) return null;
              final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input);
              return valid ? null : 'Enter a valid email';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Website (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _governmentRegistrationController,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Government registration number (optional)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: _buildInputDecoration(tr('service_description')),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return tr('please_describe_service');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('${tr('price_or_rate')} (optional)'),
            validator: (value) {
              final raw = value?.trim() ?? '';
              if (raw.isEmpty) {
                return null;
              }
              final parsed = double.tryParse(raw.replaceAll(',', '.'));
              if (parsed == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildImagePicker(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
                        onPressed: _isSubmittingListing ? null : _submitJobListing,
                        child: _isSubmittingListing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061E12)),
                                ),
                              )
                            : Text(tr('publish_job_listing'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Jobs / Services / Market', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (widget.searchOnly)
            TextButton.icon(
              onPressed: () {
                if (!AccessControl.ensureApprovedContributor(context, actionLabel: tr('publish_job_listing'))) {
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JobsScreen(
                      initialCategory: _selectedCategory,
                      showSubmissionOnly: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.post_add_outlined, color: Color(0xFFF59E0B), size: 18),
              label: const Text('Post', style: TextStyle(color: Color(0xFFF59E0B))),
            ),
          AppLocalizationHelper.languageMenu(context),
        ],
      ),
      backgroundColor: const Color(0xFF061E12),
      body: RefreshIndicator(
        onRefresh: _refreshJobsPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              if (widget.searchOnly) ...[
                _buildPremiumJobsHero(),
                const SizedBox(height: 16),
                _buildBrowsePublicJobs(),
              ] else if (!widget.showSubmissionOnly) ...[
                _buildPremiumJobsHero(),
                const SizedBox(height: 16),
                _buildCategoryBrowser(),
                const SizedBox(height: 16),
                _buildBrowsePublicJobs(),
                const SizedBox(height: 20),
              ],
              if (widget.showSubmissionOnly) ...[
                _buildFormSectionCard(
                  child: Text(
                    'Submit $_selectedCategory Service',
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                formCard,
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumJobsHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF123222), Color(0xFF0A2418), Color(0xFF1F3F2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Hub: Jobs, Services, Market',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Find providers faster, browse verified listings, and publish your own service from one place.',
            style: TextStyle(color: Color(0xFFE8D79B), fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: const Color(0xFF0E2E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }
}

IconData _iconForServiceCategory(String category) {
  final key = category.toLowerCase();
  if (key.contains('miscellaneous') || key.contains('other')) return Icons.category_outlined;
  if (key.contains('clean')) return Icons.cleaning_services_outlined;
  if (key.contains('mechanic')) return Icons.build_circle_outlined;
  if (key.contains('car wash')) return Icons.local_car_wash_outlined;
  if (key.contains('photo') || key.contains('video')) return Icons.perm_media_outlined;
  if (key.contains('dj')) return Icons.music_note_outlined;
  if (key.contains('electric')) return Icons.electrical_services_outlined;
  if (key.contains('paint')) return Icons.format_paint_outlined;
  if (key.contains('furniture') || key.contains('carpentry')) return Icons.chair_outlined;
  if (key.contains('garden')) return Icons.yard_outlined;
  if (key.contains('catering')) return Icons.restaurant_outlined;
  if (key.contains('decor')) return Icons.celebration_outlined;
  if (key.contains('medical') || key.contains('doctor') || key.contains('pharmacist')) return Icons.medical_services_outlined;
  if (key.contains('legal')) return Icons.balance_outlined;
  if (key.contains('translator')) return Icons.translate_outlined;
  if (key.contains('airport') || key.contains('taxi') || key.contains('pickup')) return Icons.airport_shuttle_outlined;
  if (key.contains('truck') || key.contains('logistics')) return Icons.local_shipping_outlined;
  return Icons.miscellaneous_services_outlined;
}

class JobCategoryPage extends StatefulWidget {
  const JobCategoryPage({super.key, required this.category});

  final String category;

  @override
  State<JobCategoryPage> createState() => _JobCategoryPageState();
}

class _JobCategoryPageState extends State<JobCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _providerIdFromData(Map<String, dynamic> data) {
    final rawId = (data['__docId'] ?? '').toString().trim();
    if (rawId.isNotEmpty) return rawId;
    final fallback = (data['title'] ?? data['providerName'] ?? data['authorName'] ?? 'provider').toString();
    return fallback.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
  }

  bool _isTranslatorCategory() {
    return widget.category.toLowerCase().contains('translator');
  }

  String _reviewTargetKey(String providerId) => 'provider_$providerId';

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value == null ? '' : value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _providerEmail(Map<String, dynamic> data) {
    return _firstNonEmpty([
      data['email'],
      data['businessEmail'],
      data['contactEmail'],
    ]);
  }

  String _providerWebsite(Map<String, dynamic> data) {
    final links = data['links'];
    final linkWebsite = links is Map<String, dynamic> ? links['website'] : null;
    return _firstNonEmpty([
      data['website'],
      data['webSite'],
      data['businessWebsite'],
      linkWebsite,
    ]);
  }

  String _providerGovernmentRegistration(Map<String, dynamic> data) {
    return _firstNonEmpty([
      data['governmentRegistrationNumber'],
      data['registrationNumber'],
      data['serialRegistrationNumber'],
    ]);
  }

  String _providerListingType(Map<String, dynamic> data) {
    return _firstNonEmpty([
      data['listingType'],
      data['profileType'],
      data['businessType'],
    ]);
  }

  bool _isBusinessOrProfessionalListing(Map<String, dynamic> data) {
    final listingType = _providerListingType(data).toLowerCase();
    if (listingType == 'business' || listingType == 'professional') {
      return true;
    }

    final category = _firstNonEmpty([data['category'], widget.category]).toLowerCase();
    return category.contains('business')
        || category.contains('professional')
        || category.contains('medical')
        || category.contains('legal')
        || category.contains('translator');
  }

  bool _hasGoldVerification(Map<String, dynamic> data) {
    return _providerGovernmentRegistration(data).isNotEmpty
        && _isBusinessOrProfessionalListing(data);
  }

  Future<void> _openWebsite(String website) async {
    final trimmed = website.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.startsWith('http://') || trimmed.startsWith('https://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website.')),
      );
    }
  }

  Future<void> _openEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: trimmed);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  Future<void> _openProviderThread(Map<String, dynamic> data) async {
    if (_needsRegistration) {
      _showRegistrationPrompt('chat with this provider');
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    String firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value == null ? '' : value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    var providerUid = firstNonEmpty([
      data['userId'],
      data['user_id'],
      data['providerUid'],
      data['ownerUid'],
      data['authorUid'],
      data['postedByUid'],
      data['postedBy'],
      data['createdByUid'],
      data['createdBy'],
      data['submittedByUid'],
      data['uid'],
    ]);
    final providerName = (data['providerName'] ?? data['authorName'] ?? data['title'] ?? 'Provider').toString().trim();
    final postId = (data['__docId'] ?? data['sourceSubmissionId'] ?? '').toString().trim();
    final postType = 'jobs';
    final postTitle = (data['title'] ?? '$providerName - ${widget.category}').toString().trim();
    final postCategory = (data['category'] ?? widget.category).toString().trim();
    final providerPhone = (data['phone'] ?? data['authorPhone'] ?? '').toString().trim();
    final providerEmail = _providerEmail(data);

    if (providerUid.isEmpty) {
      final sourceCollection = (data['sourceCollection'] ?? '').toString().trim();
      final sourceId = firstNonEmpty([data['sourceId'], data['sourceSubmissionId'], postId]);
      if (sourceCollection.isNotEmpty && sourceId.isNotEmpty) {
        try {
          final sourceDoc = await FirebaseFirestore.instance.collection(sourceCollection).doc(sourceId).get();
          if (sourceDoc.exists) {
            final sourceData = sourceDoc.data() ?? const <String, dynamic>{};
            providerUid = firstNonEmpty([
              sourceData['userId'],
              sourceData['user_id'],
              sourceData['providerUid'],
              sourceData['ownerUid'],
              sourceData['authorUid'],
              sourceData['postedByUid'],
              sourceData['postedBy'],
              sourceData['createdByUid'],
              sourceData['createdBy'],
              sourceData['submittedByUid'],
              sourceData['uid'],
              providerUid,
            ]);
          }
        } on FirebaseException {
          // Ignore non-readable source docs.
        }
      }
    }

    if (providerUid.isEmpty && postId.isNotEmpty) {
      final jobDoc = await FirebaseFirestore.instance.collection('jobs').doc(postId).get();
      if (jobDoc.exists) {
        final jobData = jobDoc.data() ?? const <String, dynamic>{};
        providerUid = firstNonEmpty([
          jobData['userId'],
          jobData['user_id'],
          jobData['providerUid'],
          jobData['ownerUid'],
          jobData['authorUid'],
          jobData['postedByUid'],
          jobData['postedBy'],
          jobData['createdByUid'],
          jobData['createdBy'],
          jobData['submittedByUid'],
          jobData['uid'],
          providerUid,
        ]);
      }
    }

    if (!mounted) return;

    if (providerUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Direct chat is available after provider account is linked.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderChatThreadScreen(
          providerUid: providerUid,
          providerName: providerName.isEmpty ? 'Provider' : providerName,
          postId: postId,
          postType: postType,
          postTitle: postTitle,
          postCategory: postCategory,
          providerPhone: providerPhone,
          providerEmail: providerEmail,
        ),
      ),
    );
  }

  bool get _needsRegistration {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      if (SessionState.isGuest || !SessionState.isVerified) {
        final contact = (authUser.email ?? authUser.uid).trim();
        SessionState.markVerified(
          contact,
          approved: true,
          uid: authUser.uid,
          name: (authUser.displayName ?? '').trim().isEmpty ? null : authUser.displayName,
        );
      }
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRegistrationPrompt(String actionLabel) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: const Text(
            'Create an Account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You can browse ${widget.category} services freely. Register or sign in if you want to $actionLabel.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Maybe later', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text('Register / Sign In'),
            ),
          ],
        );
      },
    );
  }

  void _openJobPortal() {
    if (_needsRegistration) {
      _showRegistrationPrompt('post a job or manage your services');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobsScreen(initialCategory: widget.category)),
    );
  }

  void _showProviderProfile(Map<String, dynamic> data) {
    final providerName = (data['providerName'] ?? data['authorName'] ?? data['title'] ?? 'Service Provider').toString();
    final city = (data['city'] ?? '').toString();
    final country = (data['country'] ?? '').toString();
    final email = _providerEmail(data);
    final website = _providerWebsite(data);
    final description = (data['description'] ?? 'No profile description yet.').toString();
    final phone = _firstNonEmpty([data['phone'], data['authorPhone']]);
    final userId = (data['userId'] ?? '').toString().trim();
    final postId = (data['__docId'] ?? data['sourceSubmissionId'] ?? '').toString().trim();
    final title = (data['title'] ?? providerName).toString();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceProfileDetailScreen(
          title: title,
          category: (data['category'] ?? widget.category).toString(),
          description: description,
          providerName: providerName,
          city: [city, country].where((e) => e.trim().isNotEmpty).join(', '),
          phone: phone,
          email: email,
          website: website,
          userId: userId,
          postId: postId,
          postType: 'jobs',
        ),
      ),
    );
  }

  Future<void> _toggleFollow(Map<String, dynamic> data) async {
    if (_needsRegistration) {
      _showRegistrationPrompt('follow this provider');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final providerId = _providerIdFromData(data);
    final providerName = (data['providerName'] ?? data['authorName'] ?? data['title'] ?? 'Provider').toString();
    final docId = '${uid}_$providerId';
    final ref = FirebaseFirestore.instance.collection('provider_follows').doc(docId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed provider.')));
      return;
    }

    await ref.set({
      'uid': uid,
      'providerId': providerId,
      'providerName': providerName,
      'category': widget.category,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider followed.')));
  }

  Future<void> _toggleLike(Map<String, dynamic> data) async {
    if (_needsRegistration) {
      _showRegistrationPrompt('like this job profile');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final providerId = _providerIdFromData(data);
    final title = (data['title'] ?? data['providerName'] ?? 'Job').toString();
    final docId = '${uid}_$providerId';
    final ref = FirebaseFirestore.instance.collection('job_likes').doc(docId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed like.')));
      return;
    }

    await ref.set({
      'uid': uid,
      'providerId': providerId,
      'title': title,
      'category': widget.category,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liked.')));
  }

  Future<void> _showReviewComposer(Map<String, dynamic> data) async {
    if (_needsRegistration) {
      _showRegistrationPrompt('review this provider');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final providerId = _providerIdFromData(data);
    final providerName = (data['providerName'] ?? data['authorName'] ?? data['title'] ?? 'Provider').toString();
    final controller = TextEditingController();
    double rating = 5;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setLocal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0E2E1E),
              title: Text('Review $providerName', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating: ${rating.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (v) => setLocal(() => rating = v),
                  ),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write your review',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF123222),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: () async {
                    final comment = controller.text.trim();
                    if (comment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please write a short review.')),
                      );
                      return;
                    }
                    final targetKey = _reviewTargetKey(providerId);
                    final rounded = rating.round();

                    final reviewsRef = FirebaseFirestore.instance.collection('Reviews').doc();
                    final summaryRef = FirebaseFirestore.instance.collection('ReviewSummaries').doc(targetKey);
                    final reviewerName = (FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'Anonymous').toString();

                    await FirebaseFirestore.instance.runTransaction((txn) async {
                      final summarySnap = await txn.get(summaryRef);
                      final current = summarySnap.data() ?? const <String, dynamic>{};
                      final currentCount = (current['reviewCount'] is num) ? (current['reviewCount'] as num).toInt() : 0;
                      final currentTotal = (current['ratingTotal'] is num) ? (current['ratingTotal'] as num).toDouble() : 0;
                      final nextCount = currentCount + 1;
                      final nextTotal = currentTotal + rounded.toDouble();
                      final nextAverage = nextTotal / nextCount;

                      txn.set(reviewsRef, {
                        'reviewerUid': uid,
                        'reviewerName': reviewerName,
                        'targetType': 'provider',
                        'targetId': providerId,
                        'targetKey': targetKey,
                        'rating': rounded,
                        'comment': comment,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      txn.set(summaryRef, {
                        'targetKey': targetKey,
                        'targetType': 'provider',
                        'targetId': providerId,
                        'reviewCount': nextCount,
                        'ratingTotal': nextTotal,
                        'averageRating': nextAverage,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    });

                    if (!mounted || !dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks! Your review was submitted.')),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  bool _matchesQuery(Map<String, dynamic> data) {
    if (_searchQuery.trim().isEmpty) return true;

    final query = _searchQuery.toLowerCase().trim();
    final haystack = [
      (data['title'] ?? '').toString(),
      (data['providerName'] ?? '').toString(),
      (data['authorName'] ?? '').toString(),
      (data['description'] ?? '').toString(),
      (data['city'] ?? '').toString(),
      (data['country'] ?? '').toString(),
      (data['category'] ?? '').toString(),
      _providerEmail(data),
      _providerWebsite(data),
      _providerGovernmentRegistration(data),
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  bool _isCategoryMatch(String selectedCategory, String dataCategory) {
    String normalize(String input) {
      return input
          .toLowerCase()
          .replaceAll('&', ' and ')
          .replaceAll('/', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final selected = normalize(selectedCategory);
    final current = normalize(dataCategory);
    if (selected == current) return true;

    bool containsAny(String value, List<String> tokens) => tokens.any(value.contains);

    if (containsAny(selected, ['photo', 'video', 'videography'])) {
      return containsAny(current, ['photo', 'video', 'videography']);
    }
    if (containsAny(selected, ['furniture', 'carpentry'])) {
      return containsAny(current, ['furniture', 'carpentry']);
    }
    if (containsAny(selected, ['medical', 'doctor', 'pharmacist'])) {
      return containsAny(current, ['medical', 'doctor', 'pharmacist']);
    }
    if (containsAny(selected, ['airport', 'pickup', 'logistics', 'taxi', 'truck'])) {
      return containsAny(current, ['airport', 'pickup', 'logistics', 'taxi', 'truck']);
    }
    if (containsAny(selected, ['miscellaneous', 'other'])) {
      return containsAny(current, ['miscellaneous', 'other']);
    }

    return false;
  }

  Widget _buildCategoryHeader() {
    final iconSize = _isTranslatorCategory() ? 28.0 : 22.0;
    final iconBox = _isTranslatorCategory() ? 56.0 : 42.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: const Color(0x2210B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForServiceCategory(widget.category), size: iconSize, color: const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.category,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Search services, review provider profiles, and contact providers when you are ready to hire.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: _openJobPortal,
                icon: Icon(_needsRegistration ? Icons.person_add_alt_1 : Icons.work_outline),
                label: Text(_needsRegistration ? 'Register to Post / Manage' : 'Open Job Portal'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                ),
                onPressed: () => _showRegistrationPrompt('contact or hire a service provider'),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Why register?'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search jobs or services in ${widget.category}',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
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
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> data) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final providerId = _providerIdFromData(data);
    final targetKey = _reviewTargetKey(providerId);
    final providerName = (data['providerName'] ?? data['authorName'] ?? data['title'] ?? 'Service Provider').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final email = _providerEmail(data);
    final website = _providerWebsite(data);
    final registrationNumber = _providerGovernmentRegistration(data);
    final isGoldVerified = _hasGoldVerification(data);
    final city = (data['city'] ?? '').toString();
    final country = (data['country'] ?? '').toString();
    final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0;

    return Card(
      color: const Color(0xFF0E2E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF123222),
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Icon(
                          _iconForServiceCategory(widget.category),
                          size: _isTranslatorCategory() ? 30 : 22,
                          color: const Color(0xFFF59E0B),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              providerName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          if (isGoldVerified)
                            const Tooltip(
                              message: 'Government registration verified',
                              child: Icon(Icons.verified, color: Color(0xFFFFD700), size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.category,
                        style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      if (city.isNotEmpty || country.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$city${city.isNotEmpty && country.isNotEmpty ? ', ' : ''}$country',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  price > 0 ? 'EUR ${price.toStringAsFixed(0)}' : 'Negotiable',
                  style: const TextStyle(color: Color(0xFFE8D79B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
            if (registrationNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Gov registration: $registrationNumber',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
            if (email.isNotEmpty || website.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (email.isNotEmpty)
                    InkWell(
                      onTap: () => _openEmail(email),
                      child: Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (website.isNotEmpty)
                    InkWell(
                      onTap: () => _openWebsite(website),
                      child: Text(
                        website,
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('ReviewSummaries').doc(targetKey).snapshots(),
              builder: (context, reviewSnap) {
                final summary = reviewSnap.data?.data() ?? const <String, dynamic>{};
                final count = (summary['reviewCount'] is num) ? (summary['reviewCount'] as num).toInt() : 0;
                final avg = (summary['averageRating'] is num) ? (summary['averageRating'] as num).toDouble() : 0;
                return Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      count > 0 ? '${avg.toStringAsFixed(1)} ($count)' : 'No reviews yet',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                  onPressed: () => _showProviderProfile(data),
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('View Profile'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: () => _openProviderThread(data),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(_needsRegistration ? 'Register to Contact' : 'Contact / Hire'),
                ),
                if (uid.isNotEmpty)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('provider_follows').doc('${uid}_$providerId').snapshots(),
                    builder: (context, followSnap) {
                      final following = followSnap.data?.exists == true;
                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: following ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          side: BorderSide(color: following ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                        ),
                        onPressed: () => _toggleFollow(data),
                        icon: Icon(following ? Icons.person_remove_alt_1 : Icons.person_add_alt_1),
                        label: Text(following ? 'Following' : 'Follow'),
                      );
                    },
                  ),
                if (uid.isNotEmpty)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('job_likes').doc('${uid}_$providerId').snapshots(),
                    builder: (context, likeSnap) {
                      final liked = likeSnap.data?.exists == true;
                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: liked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                          side: BorderSide(color: liked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                        ),
                        onPressed: () => _toggleLike(data),
                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                        label: Text(liked ? 'Liked' : 'Like'),
                      );
                    },
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                  onPressed: () => _showReviewComposer(data),
                  icon: const Icon(Icons.star_rate_outlined),
                  label: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        centerTitle: true,
        title: Text(widget.category, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('jobs').limit(80).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }

          final docs = snapshot.data?.docs ?? [];
          final filtered = docs
              .map((doc) => <String, dynamic>{...doc.data(), '__docId': doc.id})
              .where((data) => (data['status'] ?? '').toString() == 'approved')
              .where((data) => _isCategoryMatch(widget.category, (data['category'] ?? '').toString()))
              .where(_matchesQuery)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCategoryHeader(),
              const SizedBox(height: 14),
              _buildSearchBar(),
              const SizedBox(height: 12),
              Text(
                '${filtered.length} providers found',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'No approved providers found in this category yet. Try another search or come back later.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                )
              else
                ...filtered.map(_buildProviderCard),
            ],
          );
        },
      ),
    );
  }
}
