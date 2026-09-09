import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cash_on_delivery_order_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  String selectedCategory = 'All';

  final List<String> categories = [
    'All', 'Vehicles', 'Electronics', 'Home & Furniture', 'Traditional / Habesha', 'Clothing'
  ];

  // ── የገበያው እቃዎች (ከነ ሙሉ ዴቴላቸው) ──
  final List<Map<String, dynamic>> products = [
    {
      'title': 'Traditional Habesha Coffee Set (Sini)',
      'price': '€45',
      'location': 'Lyon, France',
      'condition': 'New',
      'time': 'Listed 2 hours ago',
      'sellerName': 'Abebe Kebede',
      'sellerPhone': '+33 6 12 34 56 78',
      'description': 'Original Ethiopian clay coffee set (Jebena, 6 Sini, and Zelencha). Perfect condition, imported directly from Addis Ababa.',
      'image': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'iPhone 13 Pro Max - 256GB',
      'price': '€550',
      'location': 'Paris, France',
      'condition': 'Used - Like New',
      'time': 'Listed 5 hours ago',
      'sellerName': 'Dawit M.',
      'sellerPhone': '+33 6 98 76 54 32',
      'description': 'Battery health 88%. No scratches. Comes with original box and charger cable. Cash or instant transfer upon meetup in Paris.',
      'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Volkswagen Golf 7 - 2018',
      'price': '€12,500',
      'location': 'Marseille, France',
      'condition': 'Used - Good',
      'time': 'Listed 1 day ago',
      'sellerName': 'Samrawit T.',
      'sellerPhone': '+33 6 55 44 33 22',
      'description': 'Diesel, Manual transmission, 140,000 km. Technical control (CT) passed last month. Full service history available.',
      'image': 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Ethiopian Traditional Dress (Habesha Kemis)',
      'price': '€120',
      'location': 'Frankfurt, Germany',
      'condition': 'New',
      'time': 'Listed 2 days ago',
      'sellerName': 'Marta E.',
      'sellerPhone': '+49 151 23456789',
      'description': 'Hand-woven Habesha Kemis with traditional Tibeb. Size Medium-Large. Brand new, never worn.',
      'image': 'https://images.unsplash.com/photo-1583391733958-d15317a86976?auto=format&fit=crop&w=800&q=80',
    },
  ];

  // ፖስት ማድረጊያ መቆጣጠሪያዎች (Controllers)
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _itemCondition = 'New';
  String _selectedRegion = 'Lyon, France';
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _marketPhotos = [];

  final List<String> _regions = const [
    'Paris, France',
    'Lyon, France',
    'Marseille, France',
    'Brussels, Belgium',
    'Amsterdam, Netherlands',
    'London, UK',
    'Lisbon, Portugal',
    'Madrid, Spain',
    'Rome, Italy',
    'Zurich, Switzerland',
    'Frankfurt, Germany',
    'Stockholm, Sweden',
  ];

  Future<void> _pickMarketPhotos(StateSetter modalSetState) async {
    final picked = await _picker.pickMultiImage(limit: 3 - _marketPhotos.length);
    if (picked.isEmpty) return;
    modalSetState(() {
      _marketPhotos.addAll(picked.take(3 - _marketPhotos.length));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── 1. እቃ ለመሸጥ ፎርም (Sell Bottom Sheet) ──
  void _showSellForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: primaryDarkGreen,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create Listing', style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryGold.withOpacity(0.5)),
                ),
                child: InkWell(
                  onTap: _marketPhotos.length >= 3 ? null : () => _pickMarketPhotos(modalSetState),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: primaryGold, size: 30),
                    const SizedBox(height: 4),
                    Text('Add Item Photos (${_marketPhotos.length}/3)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                ),
              ),
              if (_marketPhotos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _marketPhotos.map((photo) => Chip(
                    label: Text(photo.name, overflow: TextOverflow.ellipsis),
                    onDeleted: () {
                      modalSetState(() => _marketPhotos.remove(photo));
                      setState(() {});
                    },
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),

              _buildTextField('Title *', 'What are you selling?', _titleController),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Price (€) *', '0.00', _priceController, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Condition', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: cardGreen,
                              value: _itemCondition,
                              style: const TextStyle(color: Colors.white),
                              icon: Icon(Icons.keyboard_arrow_down, color: primaryGold),
                              items: ['New', 'Used - Like New', 'Used - Good', 'Used - Fair'].map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (val) => setState(() => _itemCondition = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRegionSelector(modalSetState),
              const SizedBox(height: 10),
              _buildTextField('Description *', 'Describe condition, delivery options...', _descController, maxLines: 3),
              const SizedBox(height: 8),
              const Text('Marketplace contact is in-app chat only. Buyers can also place a cash-on-delivery order.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _descController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all required fields!'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    setState(() {
                      products.insert(0, {
                        'title': _titleController.text,
                        'price': '€${_priceController.text}',
                        'location': _selectedRegion,
                        'condition': _itemCondition,
                        'time': 'Just now',
                        'sellerName': 'Getu A. (You)',
                        'sellerPhone': '',
                        'description': _descController.text,
                        'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80',
                        'photoPaths': _marketPhotos.map((photo) => photo.path).toList(),
                      });
                    });

                    _titleController.clear();
                    _priceController.clear();
                    _phoneController.clear();
                    _descController.clear();
                    _marketPhotos.clear();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item successfully posted to Marketplace!'), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text('Publish Item', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 30), // ከስር በቂ ቦታ እንዲኖረው
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRegionSelector(StateSetter modalSetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Region / City *', style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 11)),
        const SizedBox(height: 3),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          dropdownColor: cardGreen,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardGreen,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          items: _regions.map((region) => DropdownMenuItem<String>(value: region, child: Text(region))).toList(),
          onChanged: (value) {
            if (value == null) return;
            modalSetState(() => _selectedRegion = value);
            setState(() => _selectedRegion = value);
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontWeight: FontWeight.w600, fontSize: 11)),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: cardGreen,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: primaryDarkGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.edit_square, size: 18),
                  label: const Text('Sell', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showSellForm,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        bool isSelected = selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => selectedCategory = category),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryGold.withOpacity(0.2) : cardGreen,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? primaryGold : Colors.transparent),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? primaryGold : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.72, 
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: _buildProductCard(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                product['image'] ?? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white10,
                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['price'] ?? '€0',
                  style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  product['title'] ?? 'No Title',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white54, size: 11),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        product['location'] ?? 'Europe',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ── 2. የእቃው ሙሉ መግለጫ (Product Detail Screen) - Safe & Raised Layout ──
// ==========================================
class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);

    final String title = product['title'] ?? 'Product Details';
    final String price = product['price'] ?? '€0';
    final String location = product['location'] ?? 'Lyon, France';
    final String time = product['time'] ?? 'Recently listed';
    final String condition = product['condition'] ?? 'Good';
    final String sellerName = product['sellerName'] ?? 'Habesha Member';
    final String sellerPhone = product['sellerPhone'] ?? '+33 6 00 00 00 00';
    final String description = product['description'] ?? 'No description provided for this item.';
    final String imageUrl = product['image'] ?? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80';
    
    final String sellerInitial = sellerName.isNotEmpty ? sellerName[0] : 'H';

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
      ),
      body: SingleChildScrollView(
        // ── 💡 ከስር በቂ ተጨማሪ ቦታ (Padding) በመስጠት ከስልኩ የጌስቸር ባር ጋር እንዳይጋጭ ተደርጓል ──
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(height: 280, color: Colors.white10, child: const Icon(Icons.image, size: 50, color: Colors.white38)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price, style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 15),
                      const Icon(Icons.location_on, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primaryGold.withOpacity(0.5)),
                    ),
                    child: Text('Condition: $condition', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),

                  const Divider(color: Colors.white24, height: 30),

                  const Text('Seller Information', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryGold.withOpacity(0.2),
                          child: Text(sellerInitial, style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sellerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Text('Member of Euro Habesha Community', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24, height: 30),

                  const Text('Description', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),

                  const SizedBox(height: 50), // ── 💡 ከበተኖቹ በላይ ትልቅ ክፍተት እንዲኖር ──

                  // ── ሻጭን ማነጋገሪያ በተኖች (ከስልኩ ባር ከፍ እንዲሉ ተደርገዋል) ──
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardGreen,
                            foregroundColor: primaryGold,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: primaryGold),
                            ),
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Message sent to $sellerName!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryDarkGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Order COD', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CashOnDeliveryOrderScreen(
                                  itemType: 'marketplace',
                                  itemTitle: title,
                                  sellerName: sellerName,
                                  sellerContact: sellerPhone,
                                  price: price,
                                  sourceData: product,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30), // ከታችኛው የሃርድዌር ባር ጋር እንዳይጋጭ ተጨማሪ ቦታ
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
