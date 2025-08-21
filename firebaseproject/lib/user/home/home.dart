import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/auth/login.dart';
import 'package:firebaseproject/user/home/all_products.dart';
import 'package:firebaseproject/user/home/cart_icon.dart';
import 'package:firebaseproject/user/home/orders.dart';
import 'package:firebaseproject/user/home/product_detail.dart';
import 'package:firebaseproject/user/home/wish_list.dart';
import 'package:firebaseproject/user/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  int _currentSliderIndex = 0;

  final List<Map<String, String>> _sliderItems = [
    {
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=2787&auto=format&fit=crop',
      'title': 'New Arrivals',
      'subtitle': 'Discover the latest additions to our collection.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=2787&auto=format&fit=crop',
      'title': 'Bestsellers',
      'subtitle': 'Explore the books everyone is talking about.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=2787&auto=format&fit=crop',
      'title': 'Limited Editions',
      'subtitle': 'Rare and signed copies available now.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSlider(),
                _buildSectionHeader('Browse Genres'),
                _buildCategoriesSection(),
                _buildPromotionalBanner(),
                _buildSectionHeader('New & Noteworthy'),
                _buildProductsSlider(),
                _buildAboutCompanySection(),
                const SizedBox(height: 100),
              ],
            ).animate().fadeIn(duration: 500.ms),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('BookHaven', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold)),
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Get.offAll(() => const LoginScreen());
          },
        ),
      ],
    );
  }

  Widget _buildImageSlider() {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _sliderItems.length,
          itemBuilder: (context, index, realIndex) {
            final item = _sliderItems[index];
            return Container(
              margin: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(item['image']!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item['subtitle']!, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) => setState(() => _currentSliderIndex = index),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _sliderItems.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentSliderIndex == entry.key ? 24.0 : 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
              decoration: BoxDecoration(
                color: _currentSliderIndex == entry.key ? Colors.black : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        title,
        style: const TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').orderBy('title').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No Genres Found'));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final category = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _CategoryTile(
                title: category['title'] ?? 'N/A',
                imageUrl: category['imageUrl'] ?? 'https://via.placeholder.com/80',
                onTap: () => Get.to(() => CategoryProductsScreen(categoryId: snapshot.data!.docs[index].id, categoryTitle: category['title'])),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.5);
            },
          );
        },
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_outlined, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Editor's Pick", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Discover a curated gem, just for you.", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => Get.to(() => const AllProductsScreen()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: const BorderSide(color: Colors.black),
              backgroundColor: Colors.white,
            ),
            child: const Text('Explore', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    ).animate().scaleXY(begin: 0.8, duration: 400.ms).fadeIn();
  }

  Widget _buildProductsSlider() {
    return SizedBox(
      height: 300,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').orderBy('createdAt', descending: true).limit(8).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No Books Found'));
          return CarouselSlider.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index, realIndex) {
              final productData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Container(
                width: 180,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _ProductCard(
                  productData: productData,
                  productId: snapshot.data!.docs[index].id,
                ),
              );
            },
            options: CarouselOptions(
              height: 300,
              viewportFraction: 0.5,
              enableInfiniteScroll: false,
              padEnds: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutCompanySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About BookHaven', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Established in 2025, BookHaven was born from a simple love for reading. We believe in the power of stories to connect, inspire, and transform. Our curated collection brings together timeless classics and contemporary voices, creating a sanctuary for every reader.',
            style: TextStyle(fontSize: 14, height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 85,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(icon: Icons.person_outline, label: 'Profile', onTap: () => Get.to(() => const ProfileScreen())),
            _NavButton(icon: Icons.favorite_border, label: 'Wishlist', onTap: () => Get.to(() => const WishlistScreen())),
            const CartIconWithBadge(),
            _NavButton(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () => Get.to(() => const OrdersScreen())),
            _NavButton(icon: Icons.storefront_outlined, label: 'Store', onTap: () => Get.to(() => const AllProductsScreen())),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;
  const _CategoryTile({required this.title, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (e, s) => const AssetImage('assets/placeholder.png'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final String productId;
  const _ProductCard({required this.productData, required this.productId});

  @override
  Widget build(BuildContext context) {
    final name = productData['name'] ?? 'No Name';
    final imageUrl = productData['imageUrl'] as String?;
    final price = productData['price'] ?? 0.0;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black),
      ),
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(productId: productId, product: productData)),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                        loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.book_outlined, size: 50)),
                      )
                    : const Center(child: Icon(Icons.book_outlined, size: 50)),
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
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;
  const CategoryProductsScreen({super.key, required this.categoryId, required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: categoryId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No products found.'));
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.65),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) => _ProductCard(
              productData: snapshot.data!.docs[index].data() as Map<String, dynamic>,
              productId: snapshot.data!.docs[index].id,
            ),
          );
        },
      ),
    );
  }
}