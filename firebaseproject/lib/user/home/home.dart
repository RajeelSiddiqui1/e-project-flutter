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
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

Future<void> _toggleWishlist(
    String productId, Map<String, dynamic> productData, bool isWishlisted) async {
  if (user == null) {
    Get.snackbar('Error', 'Please log in to manage your wishlist');
    return;
  }

  final wishlistRef = _firestore
      .collection('wishlist')
      .doc(user!.uid) // user ke uid ke andar
      .collection('items')
      .doc(productId);

  if (isWishlisted) {
    // Agar already wishlist me hai to delete karo
    await wishlistRef.delete();
    Get.snackbar('Removed', '${productData['name']} removed from wishlist');
  } else {
    // Add to wishlist
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoriesSection(),
                  _buildSectionHeader('New & Noteworthy'),
                  _buildProductsSection(),
                  _buildAboutCompanySection(),
                  const SizedBox(height: 100),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),
            _buildBottomNavBar(),
          ],
        ),
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
      elevation: 0,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('products').orderBy('createdAt', descending: true).limit(8).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _ShimmerGrid();
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64),
                SizedBox(height: 16),
                Text('No Books Found', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Check back later for new arrivals!'),
              ],
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final productData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final productId = snapshot.data!.docs[index].id;
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('wishlist').doc(user?.uid).collection('items').doc(productId).snapshots(),
              builder: (context, wishlistSnapshot) {
                bool isWishlisted = wishlistSnapshot.data?.exists ?? false;
                return _ProductCard(
                  productData: productData,
                  productId: productId,
                  isWishlisted: isWishlisted,
                  onWishlistToggle: () => _toggleWishlist(productId, productData, isWishlisted),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('categories').orderBy('title').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _ShimmerList();
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64),
                SizedBox(height: 16),
                Text('No Genres Found', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }
        return ExpansionTile(
          title: Text('Browse Genres', style: Theme.of(context).textTheme.titleLarge),
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final category = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _CategoryTile(
                    title: category['title'] ?? 'N/A',
                    imageUrl: category['imageUrl'] ?? 'https://via.placeholder.com/80',
                    onTap: () => Get.to(() => CategoryProductsScreen(categoryId: snapshot.data!.docs[index].id, categoryTitle: category['title'])),
                  ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide()),
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

  Widget _buildAboutCompanySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About BookHaven',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'BookHaven is your go-to destination for the latest and greatest in books. Discover new genres, authors, and stories every week!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
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
            Text(label, style: Theme.of(context).textTheme.bodySmall),
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
                border: Border.all(),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (e, s) => const AssetImage('assets/placeholder.png'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(),
      ),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[300],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 16, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(width: 60, height: 16, color: Colors.grey[300]),
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

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 60, height: 14, color: Colors.grey[300]),
            ],
          ),
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
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: categoryId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const _ShimmerGrid();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64),
                    SizedBox(height: 16),
                    Text('No Products Found', style: TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final productData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final productId = snapshot.data!.docs[index].id;
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('wishlist').doc(FirebaseAuth.instance.currentUser?.uid).collection('items').doc(productId).snapshots(),
                  builder: (context, wishlistSnapshot) {
                    bool isWishlisted = wishlistSnapshot.hasData && wishlistSnapshot.data!.exists;
                    return _ProductCard(
                      productData: productData,
                      productId: productId,
                      isWishlisted: isWishlisted,
                      onWishlistToggle: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          Get.snackbar('Error', 'Please log in to manage your wishlist');
                          return;
                        }
                        final wishlistRef = FirebaseFirestore.instance.collection('wishlist').doc(user.uid).collection('items').doc(productId);
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
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}