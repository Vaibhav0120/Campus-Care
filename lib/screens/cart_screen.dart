import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/screens/place_order_screen.dart';
import 'package:campus_care/widgets/cart_tile.dart';
import 'package:lottie/lottie.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated) {
        cartProvider.loadCartItems(authProvider.user!.id);
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    // Responsive breakpoints - FIXED to use only width, not kIsWeb
    final isSmallMobile = size.width < 360;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;
    
    // Adjust font sizes and spacing based on screen size
    final double titleSize = isSmallMobile ? 18 : isTablet ? 24 : 22;
    final double emptyCartImageSize = isSmallMobile ? 150 : isTablet ? 300 : isDesktop ? 250 : 200;
    final double emptyCartTextSize = isSmallMobile ? 18 : isTablet ? 26 : isDesktop ? 24 : 20;
    final double emptyCartSubtextSize = isSmallMobile ? 14 : isTablet ? 20 : isDesktop ? 18 : 16;
    final double buttonPadding = isSmallMobile ? 16 : isTablet ? 36 : isDesktop ? 32 : 24;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
          ),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: cartProvider.isLoading
            ? Center(
                child: SizedBox(
                  width: isSmallMobile ? 100 : 150,
                  height: isSmallMobile ? 100 : 150,
                  child: Lottie.network(
                    'https://assets5.lottiefiles.com/packages/lf20_p8bfn5to.json',
                    repeat: true,
                  ),
                ),
              )
            : _buildCartContent(
                cartProvider, 
                theme, 
                isSmallMobile,
                isMobile,
                isTablet,
                isDesktop,
                emptyCartImageSize,
                emptyCartTextSize,
                emptyCartSubtextSize,
                buttonPadding,
              ),
      ),
      bottomNavigationBar: _buildBottomBar(
        cartProvider, 
        theme, 
        isSmallMobile,
        isMobile,
        isTablet,
        isDesktop,
      ),
    );
  }

  Widget _buildCartContent(
    CartProvider cartProvider, 
    ThemeData theme,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    double emptyCartImageSize,
    double emptyCartTextSize,
    double emptyCartSubtextSize,
    double buttonPadding,
  ) {
    if (cartProvider.error != null) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Error: ${cartProvider.error}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: isSmallMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                cartProvider.loadCartItems(authProvider.user!.id);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEC62B),
                foregroundColor: Colors.black87,
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
    
    if (cartProvider.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets2.lottiefiles.com/private_files/lf30_ghysqmiq.json',
              width: emptyCartImageSize,
              repeat: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: emptyCartTextSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some delicious items to your cart',
              style: TextStyle(
                fontSize: emptyCartSubtextSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Browse Menu'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                  vertical: isSmallMobile ? 10 : isTablet ? 18 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFFFEC62B),
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }
    
    final size = MediaQuery.of(context).size;
    // Desktop and large tablet layout (side-by-side)
    if (isDesktop || (isTablet && size.width >= 768)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart items list (2/3 of the screen)
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartProvider.cartItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CartTile(cartItem: cartItem),
                );
              },
            ),
          ),
          
          // Order summary (1/3 of the screen)
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(isSmallMobile ? 12 : 16),
              padding: EdgeInsets.all(isSmallMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFFEC62B).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Color(0xFFFEC62B),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFEC62B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallMobile ? 16 : 24),
                  
                  // Items count with enhanced design
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items (${cartProvider.cartItems.length})',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 12 : 16),
                    child: const Divider(),
                  ),
                  
                  // Total with enhanced design
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEC62B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFEC62B).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallMobile ? 12 : 16,
                            vertical: isSmallMobile ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEC62B),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFEC62B).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Checkout button with enhanced design
                  SizedBox(
                    width: double.infinity,
                    height: isSmallMobile ? 48 : 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlaceOrderScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Proceed to Checkout'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFFEC62B),
                        foregroundColor: Colors.black87,
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Mobile layout with enhanced design
    return ListView.builder(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = cartProvider.cartItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CartTile(cartItem: cartItem),
        );
      },
    );
  }

  Widget _buildBottomBar(
    CartProvider cartProvider, 
    ThemeData theme,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    // Don't show bottom bar for empty cart or desktop layout
    if (cartProvider.cartItems.isEmpty || isDesktop || (isTablet && MediaQuery.of(context).size.width >= 768)) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // For tablet, show a more detailed summary
          if (isTablet)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items (${cartProvider.cartItems.length})',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: Color(0xFFFEC62B),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFEC62B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: isSmallMobile ? 44 : 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlaceOrderScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(isSmallMobile ? 'Checkout' : 'Proceed to Checkout'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 16 : 24,
                      vertical: isSmallMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFFFEC62B),
                    foregroundColor: Colors.black87,
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}