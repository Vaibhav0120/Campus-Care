import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/screens/place_order_screen.dart';
import 'package:campus_care/widgets/cart_tile.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated) {
        cartProvider.loadCartItems(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        elevation: 0,
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCartContent(cartProvider, theme, isDesktop),
      bottomNavigationBar: _buildBottomBar(cartProvider, theme, isDesktop),
    );
  }

  Widget _buildCartContent(CartProvider cartProvider, ThemeData theme, bool isDesktop) {
    if (cartProvider.error != null) {
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
              'Error: ${cartProvider.error}',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                cartProvider.loadCartItems(authProvider.user!.id);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some delicious items to your cart',
              style: TextStyle(
                fontSize: 16,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (isDesktop) {
      return Row(
        children: [
          // Cart items list (2/3 of the screen)
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartProvider.cartItems[index];
                return CartTile(cartItem: cartItem);
              },
            ),
          ),
          
          // Order summary (1/3 of the screen)
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Items count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items (${cartProvider.cartItems.length})',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Delivery fee (you can add this if needed)
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       'Delivery Fee',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         color: Colors.grey[700],
                  //       ),
                  //     ),
                  //     Text(
                  //       '₹0.00',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w500,
                  //         color: Colors.grey[800],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Checkout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlaceOrderScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
    
    // Mobile layout
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = cartProvider.cartItems[index];
        return CartTile(cartItem: cartItem);
      },
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider, ThemeData theme, bool isDesktop) {
    if (cartProvider.cartItems.isEmpty || isDesktop) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlaceOrderScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
