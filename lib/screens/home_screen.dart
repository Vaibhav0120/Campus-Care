import 'package:campus_care/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/item_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/screens/auth/login_screen.dart';
import 'package:campus_care/screens/staff/staff_dashboard.dart';
import 'package:campus_care/widgets/item_card.dart';
import 'package:campus_care/screens/cart_screen.dart';
import 'package:campus_care/widgets/recommendation_carousel.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/screens/order_history_screen.dart';
import 'package:campus_care/widgets/theme_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _recommendationController;
  // ignore: unused_field
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
        allItems.where((item) => item.availableToday).toList());

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
          _currentRecommendationIndex =
              (_currentRecommendationIndex + 1) % _recommendations.length;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Responsive breakpoints
    final isSmallMobile = size.width < 360;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;

    // Determine grid columns based on screen size
    int gridColumns;
    if (isDesktop) {
      gridColumns =
          size.width > 1400 ? 6 : 5; // Extra large screens get 6 columns
    } else if (isTablet) {
      gridColumns = size.width > 750 ? 4 : 3; // Larger tablets get 4 columns
    } else if (isMobile) {
      gridColumns = 2; // Standard mobile gets 2 columns
    } else {
      gridColumns = 1; // Very small devices get 1 column
    }

    // Adjust aspect ratio based on screen size
    double cardAspectRatio;
    if (isDesktop) {
      cardAspectRatio = 0.75; // Taller cards on desktop
    } else if (isTablet) {
      cardAspectRatio = 0.7; // Slightly taller cards on tablet
    } else {
      cardAspectRatio = 0.65; // Wider cards on mobile
    }

    // Adjust spacing based on screen size
    double gridSpacing = isSmallMobile
        ? 8
        : isTablet
            ? 16
            : 12;
    double contentPadding = isSmallMobile
        ? 8
        : isTablet
            ? 24
            : 16;

    final theme = Theme.of(context);

    return Scaffold(
      body: authProvider.isAuthenticated
          ? _buildAuthenticatedContent(
              itemProvider,
              cartProvider,
              isSmallMobile,
              isMobile,
              isTablet,
              isDesktop,
              gridColumns,
              cardAspectRatio,
              gridSpacing,
              contentPadding,
              theme,
              isDarkMode)
          : _buildUnauthenticatedContent(
              isSmallMobile, isMobile, isTablet, isDesktop, theme, isDarkMode),
    );
  }

  Widget _buildAuthenticatedContent(
      ItemProvider itemProvider,
      CartProvider cartProvider,
      bool isSmallMobile,
      bool isMobile,
      bool isTablet,
      bool isDesktop,
      int gridColumns,
      double cardAspectRatio,
      double gridSpacing,
      double contentPadding,
      ThemeData theme,
      bool isDarkMode) {
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
              size: isSmallMobile ? 48 : 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: contentPadding),
              child: Text(
                'Error: ${itemProvider.error}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: isSmallMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => itemProvider.loadItems(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 16 : 24,
                  vertical: isSmallMobile ? 8 : 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Filter items based on search query
    final filteredItems = itemProvider.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();

    if (itemProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_food,
              size: isSmallMobile ? 48 : 64,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items available',
              style: TextStyle(
                fontSize: isSmallMobile ? 16 : 18,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for menu updates',
              style: TextStyle(
                fontSize: isSmallMobile ? 12 : 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
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
            title: Text(
              'Campus Care',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallMobile ? 18 : 22,
              ),
            ),
            floating: true,
            pinned: true,
            elevation: 0,
            forceElevated: innerBoxIsScrolled,
            actions: [
              // Theme toggle button
              const ThemeToggleButton(),
              
              // History button
              if (Provider.of<AuthProvider>(context).isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Order History',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                ),
              // Cart button
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
              // Logout button
              if (Provider.of<AuthProvider>(context).isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await Provider.of<AuthProvider>(context, listen: false)
                        .signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
            ],
          ),

          // Search bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverSearchBarDelegate(
              minHeight: isSmallMobile ? 70 : 90,
              maxHeight: isSmallMobile ? 70 : 90,
              child: Container(
                color: isDarkMode ? theme.appBarTheme.backgroundColor : theme.scaffoldBackgroundColor,
                child: Padding(
                  padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: isSmallMobile ? 40 : 50,
                    decoration: BoxDecoration(
                      color: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.white,
                      borderRadius: BorderRadius.circular(
                          _searchQuery.isNotEmpty ? 16 : 12),
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
                            : isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        width: _searchQuery.isNotEmpty ? 1.5 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for food items...',
                        hintStyle: TextStyle(
                          fontSize: isSmallMobile ? 12 : 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.search,
                            size: isSmallMobile ? 18 : 24,
                            color: _searchQuery.isNotEmpty
                                ? theme.primaryColor
                                : isDarkMode ? Colors.grey[400] : Colors.grey[400],
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
                                      icon: Icon(
                                        Icons.clear,
                                        size: isSmallMobile ? 18 : 24,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
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
                        fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isSmallMobile ? 0 : 4,
                          horizontal: isSmallMobile ? 8 : 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: isSmallMobile ? 12 : 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
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
              padding: EdgeInsets.symmetric(
                  horizontal: contentPadding, vertical: isSmallMobile ? 4 : 8),
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
                padding: EdgeInsets.symmetric(
                    horizontal: contentPadding,
                    vertical: isSmallMobile ? 4 : 8),
                child: Row(
                  children: [
                    Text(
                      'Found ${filteredItems.length} results for "$_searchQuery"',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallMobile ? 12 : 14,
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
                          size: isSmallMobile ? 48 : 64,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 16 : 18,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 12 : 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.all(contentPadding),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumns,
                      childAspectRatio: cardAspectRatio,
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
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
                          isSmallMobile: isSmallMobile,
                          isMobile: isMobile,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                          onAddToCart: () {
                            if (cartItem.quantity > 0) {
                              // Item is already in cart, do nothing
                              return;
                            }
                            cartProvider.addToCart(
                              Provider.of<AuthProvider>(context, listen: false)
                                  .user!
                                  .id,
                              item,
                            );
                          },
                          onIncreaseQuantity: () {
                            cartProvider.updateQuantity(
                                cartItem, cartItem.quantity + 1);
                          },
                          onDecreaseQuantity: () {
                            if (cartItem.quantity > 1) {
                              cartProvider.updateQuantity(
                                  cartItem, cartItem.quantity - 1);
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

  Widget _buildUnauthenticatedContent(bool isSmallMobile, bool isMobile,
      bool isTablet, bool isDesktop, ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor.withOpacity(0.8),
                ]
              : [
                  theme.primaryColor.withOpacity(0.8),
                  theme.primaryColor.withOpacity(0.6),
                ],
        ),
      ),
      child: Center(
        child: Card(
          margin: EdgeInsets.all(isSmallMobile
              ? 16
              : isTablet
                  ? 32
                  : 24),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallMobile
                ? 16
                : isTablet
                    ? 32
                    : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: isSmallMobile
                      ? 60
                      : isTablet
                          ? 100
                          : 80,
                  color: theme.primaryColor,
                ),
                SizedBox(height: isSmallMobile ? 16 : 24),
                Text(
                  'Welcome to Campus Care',
                  style: TextStyle(
                    fontSize: isSmallMobile
                        ? 20
                        : isTablet
                            ? 28
                            : 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallMobile ? 12 : 16),
                Text(
                  'Order delicious food from your campus cafeteria',
                  style: TextStyle(
                    fontSize: isSmallMobile
                        ? 14
                        : isTablet
                            ? 18
                            : 16,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallMobile ? 16 : 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile
                          ? 24
                          : isTablet
                              ? 40
                              : 32,
                      vertical: isSmallMobile
                          ? 12
                          : isTablet
                              ? 20
                              : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: isSmallMobile
                          ? 14
                          : isTablet
                              ? 18
                              : 16,
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverSearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
