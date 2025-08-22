import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebaseproject/user/auth/login.dart';
import 'package:firebaseproject/user/home/about.dart';
import 'package:firebaseproject/user/home/all_products.dart';
import 'package:firebaseproject/user/home/cart_icon.dart';
import 'package:firebaseproject/user/home/contact.dart';
import 'package:firebaseproject/user/home/orders.dart';
import 'package:firebaseproject/user/home/product_detail.dart';
import 'package:firebaseproject/user/home/wish_list.dart';
import 'package:firebaseproject/user/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

// --- REFACTOR: Centralized Wishlist Logic ---
// This service removes duplicated code from HomeScreen and CategoryProductsScreen.
class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> toggleWishlist(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Authentication Required',
        'Please log in to manage your wishlist.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final wishlistRef = _firestore
        .collection('wishlist')
        .doc(user.uid)
        .collection('items')
        .doc(productId);
    final doc = await wishlistRef.get();
    final isWishlisted = doc.exists;
    final productName = productData['name'] ?? 'The book';

    if (isWishlisted) {
      await wishlistRef.delete();
      Get.snackbar(
        'Removed',
        '$productName has been removed from your wishlist.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } else {
      await wishlistRef.set({
        'productId': productId,
        'name': productData['name'] ?? 'No Name',
        'imageUrl': productData['imageUrl'] ?? '',
        'price': productData['price'] ?? 0.0,
        'addedAt': Timestamp.now(),
      });
      Get.snackbar(
        'Added to Wishlist',
        '$productName is now in your wishlist.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }
}
// --- END REFACTOR ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final WishlistService _wishlistService = WishlistService(); // Use the service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      // --- REFACTOR: Using a proper BottomAppBar ---
      bottomNavigationBar: _buildBottomNavBar(),
      // --- END REFACTOR ---
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Browse Genres'),
              _buildCategoriesSection(),
              _buildSectionHeader('New & Noteworthy'),
              _buildProductsSection(),
              _buildAboutCompanySection(),
              const SizedBox(height: 20), // Padding at the end
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'BookHaven',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_outlined),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Get.offAll(() => const LoginScreen());
          },
        ),
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _ShimmerGrid();
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No Books Found', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new arrivals!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68, // Adjusted for better text visibility
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final productDoc = snapshot.data!.docs[index];
            final productData = productDoc.data() as Map<String, dynamic>;
            final productId = productDoc.id;

            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('wishlist')
                  .doc(user?.uid)
                  .collection('items')
                  .doc(productId)
                  .snapshots(),
              builder: (context, wishlistSnapshot) {
                bool isWishlisted = wishlistSnapshot.data?.exists ?? false;
                return _ProductCard(
                  productData: productData,
                  productId: productId,
                  isWishlisted: isWishlisted,
                  // --- REFACTOR: Call the service ---
                  onWishlistToggle: () =>
                      _wishlistService.toggleWishlist(productId, productData),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- REFACTOR: Removed ExpansionTile for better UX ---
  Widget _buildCategoriesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('categories').orderBy('title').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _ShimmerList();
        if (snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final category =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _CategoryTile(
                title: category['title'] ?? 'N/A',
                imageUrl: category['imageUrl'] ?? '',
                onTap: () => Get.to(
                  () => CategoryProductsScreen(
                    categoryId: snapshot.data!.docs[index].id,
                    categoryTitle: category['title'],
                  ),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
            },
          ),
        );
      },
    );
  }
  // --- END REFACTOR ---

  // --- REFACTOR: A proper BottomAppBar for superior UI ---
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => Get.to(() => const ProfileScreen()),
            ),
            _NavButton(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              onTap: () => Get.to(() => const WishlistScreen()),
            ),

            _NavButton(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              onTap: () => Get.to(() => const OrdersScreen()),
            ),
            const CartIconWithBadge(),
            _NavButton(
              icon: Icons.storefront_outlined,
              label: 'Store',
              onTap: () => Get.to(() => const AllProductsScreen()),
            ),
            _NavButton(
              icon: Icons.info_outline,
              label: 'About',
              onTap: () => Get.to(() => const AboutScreen()),
            ),
            _NavButton(
              icon: Icons.contact_mail_outlined,
              label: 'Contact',
              onTap: () => Get.to(() => const ContactScreen()),
            ),
          ],
        ),
      ),
    );
  }

  // --- END REFACTOR ---

  Widget _buildAboutCompanySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About BookHaven',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BookHaven is your go-to destination for the latest and greatest in books. Discover new genres, authors, and stories every week!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
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

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
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
  const _CategoryTile({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.category, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// --- REFACTOR: Polished Product Card UI ---
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
    final price = (productData['price'] ?? 0.0).toDouble();
    final discount = (productData['discount'] ?? 0).toDouble();
    final discountedPrice = discount > 0 ? price * (1 - discount / 100) : price;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior:
          Clip.antiAlias, // Ensures content respects the border radius
      child: InkWell(
        onTap: () => Get.to(
          () => ProductDetailScreen(productId: productId, product: productData),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, p) => p == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
                                  ),
                            errorBuilder: (c, e, s) => const Center(
                              child: Icon(
                                Icons.book_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.book_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${discount.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.red : Colors.black,
                    ),
                    onPressed: onWishlistToggle,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
// --- END REFACTOR ---

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
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
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
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Container(width: 60, height: 16, color: Colors.grey[200]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
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
          width: 90,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 10),
              Container(width: 60, height: 14, color: Colors.grey[200]),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

// --- REFACTOR: CategoryProductsScreen using WishlistService ---
class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final WishlistService wishlistService =
        WishlistService(); // Use the service

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryTitle,
          style: const TextStyle(fontFamily: 'Georgia'),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('categoryId', isEqualTo: categoryId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const _ShimmerGrid();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No Books Found in this Genre',
                      style: const TextStyle(fontSize: 18),
                    ),
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
                childAspectRatio: 0.68,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final productDoc = snapshot.data!.docs[index];
                final productData = productDoc.data() as Map<String, dynamic>;
                final productId = productDoc.id;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('wishlist')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('items')
                      .doc(productId)
                      .snapshots(),
                  builder: (context, wishlistSnapshot) {
                    bool isWishlisted =
                        wishlistSnapshot.hasData &&
                        wishlistSnapshot.data!.exists;
                    return _ProductCard(
                      productData: productData,
                      productId: productId,
                      isWishlisted: isWishlisted,
                      // --- REFACTOR: Using the clean, single service call ---
                      onWishlistToggle: () => wishlistService.toggleWishlist(
                        productId,
                        productData,
                      ),
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
// --- END REFACTOR ---