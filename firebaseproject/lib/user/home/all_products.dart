import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/home/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  List<QueryDocumentSnapshot> _allProducts = [];
  List<QueryDocumentSnapshot> _filteredProducts = [];
  List<Map<String, dynamic>> _categories = [];

  String _searchText = '';
  String _selectedCategoryId = '';
  bool _showDiscountOnly = false;
  bool _showUnbeatableOnly = false;
  RangeValues _selectedPriceRange = const RangeValues(0, 10000);
  String _sortBy = 'latest';

  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadProducts();
  }

  Future<void> _loadCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    if (mounted) {
      setState(() {
        _categories = snapshot.docs.map((doc) => {'id': doc.id, 'title': doc['title'] ?? 'Unknown'}).toList();
      });
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) setState(() => _loading = true);
    final snapshot = await _firestore.collection('products').get();
    if (snapshot.docs.isNotEmpty) {
      double minP = double.infinity;
      double maxP = 0;
      for (var doc in snapshot.docs) {
        final price = (doc.data()['price'] ?? 0).toDouble();
        if (price < minP) minP = price;
        if (price > maxP) maxP = price;
      }
      _minPrice = minP;
      _maxPrice = maxP > minP ? maxP : minP + 100;
    }
    if (mounted) {
      setState(() {
        _allProducts = snapshot.docs;
        _selectedPriceRange = RangeValues(_minPrice, _maxPrice);
        _loading = false;
        _applyFilters();
      });
    }
  }

  Future<void> _toggleWishlist(String productId, Map<String, dynamic> productData, bool isWishlisted) async {
    if (user == null) {
      Get.snackbar('Error', 'Please log in to manage your wishlist');
      return;
    }

    final wishlistRef = _firestore
        .collection('wishlist')
        .doc(user!.uid)
        .collection('items')
        .doc(productId);

    if (isWishlisted) {
      await wishlistRef.delete();
      Get.snackbar('Removed', '${productData['name']} removed from wishlist');
    } else {
      await wishlistRef.set({
        'productId': productId,
        'name': productData['name'] ?? 'No Name',
        'imageUrl': productData['imageUrl'] ?? '',
        'price': productData['price'] ?? 0.0,
        'addedAt': Timestamp.now(),
      });
      Get.snackbar('Added', '${productData['name']} added to wishlist');
    }
  }

  void _applyFilters() {
    List<QueryDocumentSnapshot> filtered = List.from(_allProducts);

    if (_selectedCategoryId.isNotEmpty) {
      filtered = filtered.where((doc) => doc['categoryId'] == _selectedCategoryId).toList();
    }

    if (_showDiscountOnly) {
      filtered = filtered.where((doc) => (doc.data() as Map)['discount'] != null && doc['discount'] > 0).toList();
    }

    if (_showUnbeatableOnly) {
      filtered = filtered.where((doc) => (doc.data() as Map)['discount'] != null && doc['discount'] > 30).toList();
    }

    filtered = filtered.where((doc) {
      final price = (doc['price'] ?? 0).toDouble();
      return price >= _selectedPriceRange.start && price <= _selectedPriceRange.end;
    }).toList();

    if (_searchText.isNotEmpty) {
      final searchLower = _searchText.toLowerCase();
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final author = (data['author'] ?? '').toString().toLowerCase();
        final price = (data['price'] ?? 0).toString();
        final category = _categories.firstWhere(
          (c) => c['id'] == data['categoryId'],
          orElse: () => {'title': ''},
        )['title'].toString().toLowerCase();

        return name.contains(searchLower) ||
            author.contains(searchLower) ||
            price.contains(searchLower) ||
            category.contains(searchLower);
      }).toList();
    }

    filtered.sort((a, b) {
      Timestamp timeA = a['createdAt'] ?? Timestamp.now();
      Timestamp timeB = b['createdAt'] ?? Timestamp.now();
      return _sortBy == 'latest' ? timeB.compareTo(timeA) : timeA.compareTo(timeB);
    });

    setState(() => _filteredProducts = filtered);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedCategoryId = '';
      _showDiscountOnly = false;
      _showUnbeatableOnly = false;
      _selectedPriceRange = RangeValues(_minPrice, _maxPrice);
      _sortBy = 'latest';
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Book Store', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [Builder(builder: (context) => IconButton(icon: const Icon(Icons.filter_list), onPressed: () => Scaffold.of(context).openEndDrawer()))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, author, price, or category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                            _applyFilters();
                          });
                        })
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() {
                _searchText = val;
                _applyFilters();
              }),
            ),
          ),
        ),
      ),
      endDrawer: _buildFilterDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? const Center(child: Text('No Books Found', style: TextStyle(fontSize: 16)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index].data() as Map<String, dynamic>;
                    final productId = _filteredProducts[index].id;
                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('wishlist').doc(user?.uid).collection('items').doc(productId).snapshots(),
                      builder: (context, wishlistSnapshot) {
                        bool isWishlisted = wishlistSnapshot.data?.exists ?? false;
                        return _ProductCard(
                          productData: product,
                          productId: productId,
                          isWishlisted: isWishlisted,
                          onWishlistToggle: () => _toggleWishlist(productId, product, isWishlisted),
                        ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.3);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildFilterDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('All Categories')),
                  ..._categories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['title']))),
                ],
                onChanged: (v) => setState(() => _selectedCategoryId = v ?? ''),
              ),
              const Divider(height: 24),
              const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: _selectedPriceRange,
                min: _minPrice,
                max: _maxPrice,
                divisions: _maxPrice > _minPrice ? 100 : 1,
                labels: RangeLabels('\$${_selectedPriceRange.start.round()}', '\$${_selectedPriceRange.end.round()}'),
                onChanged: (v) => setState(() => _selectedPriceRange = v),
                onChangeEnd: (v) => _applyFilters(),
              ),
              FilterChip(
                label: const Text('On Sale Only'),
                selected: _showDiscountOnly,
                onSelected: (v) => setState(() => _showDiscountOnly = v),
              ),
              const SizedBox(height: 8),
              FilterChip(
                label: const Text('Unbeatable Deals (>30% off)'),
                selected: _showUnbeatableOnly,
                onSelected: (v) => setState(() => _showUnbeatableOnly = v),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: _clearFilters, child: const Text('Reset Filters')),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final String productId;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const _ProductCard({
    required this.productData,
    required this.productId,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = productData['name'] ?? 'No Name';
    final imageUrl = productData['imageUrl'] as String?;
    final price = productData['price'] ?? 0.0;
    final discount = (productData['discount'] ?? 0).toDouble();
    final discountedPrice = discount > 0 ? price * (1 - discount / 100) : price;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide()),
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(productId: productId, product: productData)),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorBuilder: (c, e, s) => const Center(child: Icon(Icons.book_outlined, size: 50)),
                          )
                        : const Center(child: Icon(Icons.book_outlined, size: 50)),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.red,
                        child: Text(
                          '${discount.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: isWishlisted ? Colors.red : null),
                      onPressed: onWishlistToggle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discount > 0)
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          '\$${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}