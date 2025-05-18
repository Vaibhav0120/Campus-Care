import 'package:campus_care/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/item_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/screens/login_screen.dart';
import 'package:campus_care/screens/staff/staff_dashboard.dart';
import 'package:campus_care/widgets/item_card.dart';
import 'package:campus_care/screens/cart_screen.dart';
import 'package:campus_care/widgets/recommendation_carousel.dart';
import 'package:campus_care/models/item_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _recommendationController;
  late Animation<double> _recommendationAnimation;
  int _currentRecommendationIndex = 0;
  final List<String> _recommendations = [
    'Today\'s Special',
    'Most Popular',
    'New Items',
    'Healthy Options',
    'Quick Bites'
  ];
  List<ItemModel> _recommendedItems = [];
  final ScrollController _scrollController = ScrollController();
  
  void _selectRandomRecommendations(List<ItemModel> allItems) {
    if (allItems.isEmpty) return;

    // Create a copy of the list to avoid modifying the original
    final availableItems = List<ItemModel>.from(
        allItems.where((item) => item.availableToday).toList()
    );

    // Shuffle the list to randomize
    availableItems.shuffle();

    // Take up to 3 items or all available if less than 3
    _recommendedItems = availableItems.take(3).toList();

    // If we have less than 3 items, duplicate some to make it 3
    while (_recommendedItems.length < 3 && _recommendedItems.isNotEmpty) {
      _recommendedItems.add(_recommendedItems[0]);
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation for recommendations
    _recommendationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _recommendationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _recommendationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _recommendationController.repeat(reverse: true);
    
    // Change recommendation every 5 seconds
    _recommendationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentRecommendationIndex = (_currentRecommendationIndex + 1) % _recommendations.length;
        });
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated) {
        itemProvider.loadItems().then((_) {
          _selectRandomRecommendations(itemProvider.items);
          setState(() {});
        });
        cartProvider.loadCartItems(authProvider.user!.id);
        
        // Redirect staff to staff dashboard
        if (authProvider.isStaff) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StaffDashboard()),
          );
        }
      }
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If items are loaded but recommendations are empty, select them
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    if (itemProvider.items.isNotEmpty && _recommendedItems.isEmpty) {
      _selectRandomRecommendations(itemProvider.items);
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _recommendationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: authProvider.isAuthenticated
          ? _buildAuthenticatedContent(itemProvider, cartProvider, isDesktop, theme)
          : _buildUnauthenticatedContent(theme),
    );
  }

  Widget _buildAuthenticatedContent(ItemProvider itemProvider, CartProvider cartProvider, bool isDesktop, ThemeData theme) {
    if (itemProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (itemProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${itemProvider.error}',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => itemProvider.loadItems(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Filter items based on search query
    final filteredItems = itemProvider.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
    
    if (itemProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_food,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for menu updates',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    // Use NestedScrollView to make app bar and search fixed at top
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // App Bar
          SliverAppBar(
            title: const Text(
              'Campus Care',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            floating: true,
            pinned: true,
            elevation: 0,
            forceElevated: innerBoxIsScrolled,
            actions: [
              if (Provider.of<AuthProvider>(context).isAuthenticated)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              if (Provider.of<AuthProvider>(context).isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await Provider.of<AuthProvider>(context, listen: false).signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
            ],
          ),
          
          // Search bar (fixed below app bar)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverSearchBarDelegate(
              minHeight: 90,
              maxHeight: 90,
              child: Container(
                color: theme.primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_searchQuery.isNotEmpty ? 16 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: _searchQuery.isNotEmpty 
                            ? theme.primaryColor.withOpacity(0.2) 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: _searchQuery.isNotEmpty ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: _searchQuery.isNotEmpty 
                          ? theme.primaryColor.withOpacity(0.5) 
                          : Colors.grey[200]!,
                      width: _searchQuery.isNotEmpty ? 1.5 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for food items...',
                      prefixIcon: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.search,
                          color: _searchQuery.isNotEmpty ? theme.primaryColor : Colors.grey[400],
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  ),
                                );
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      // Scrollable content area
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Recommendation carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RecommendationCarousel(
                recommendedItems: _recommendedItems,
                theme: theme,
              ),
            ),
          ),
          
          // Results count
          if (_searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Found ${filteredItems.length} results for "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Items grid
          filteredItems.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 5 : 2, // More columns on desktop
                      childAspectRatio: isDesktop ? 0.7 : 0.75, // Adjusted for desktop
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredItems[index];
                        // Find if this item is in the cart
                        final cartItem = cartProvider.cartItems.firstWhere(
                          (cartItem) => cartItem.itemId == item.id,
                          orElse: () => CartItem(
                            id: '',
                            userId: '',
                            itemId: item.id,
                            quantity: 0,
                            item: item,
                          ),
                        );
                        
                        return ItemCard(
                          item: item,
                          cartItem: cartItem,
                          onAddToCart: () {
                            if (cartItem.quantity > 0) {
                              // Item is already in cart, do nothing
                              return;
                            }
                            cartProvider.addToCart(
                              Provider.of<AuthProvider>(context, listen: false).user!.id,
                              item,
                            );
                          },
                          onIncreaseQuantity: () {
                            cartProvider.updateQuantity(cartItem, cartItem.quantity + 1);
                          },
                          onDecreaseQuantity: () {
                            if (cartItem.quantity > 1) {
                              cartProvider.updateQuantity(cartItem, cartItem.quantity - 1);
                            } else {
                              cartProvider.removeFromCart(cartItem);
                            }
                          },
                        );
                      },
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedContent(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primaryColor.withOpacity(0.8),
            theme.primaryColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Campus Care',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order delicious food from your campus cafeteria',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom delegate for the search bar
class _SliverSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverSearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverSearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}