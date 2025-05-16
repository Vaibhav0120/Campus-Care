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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCartContent(cartProvider),
      bottomNavigationBar: _buildBottomBar(cartProvider),
    );
  }

  Widget _buildCartContent(CartProvider cartProvider) {
    if (cartProvider.error != null) {
      return Center(
        child: Text(
          'Error: ${cartProvider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    
    if (cartProvider.cartItems.isEmpty) {
      return const Center(
        child: Text('Your cart is empty'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = cartProvider.cartItems[index];
        return CartTile(cartItem: cartItem);
      },
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
    if (cartProvider.cartItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51), // Using withAlpha instead of withOpacity
            spreadRadius: 1,
            blurRadius: 5,
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
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlaceOrderScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Proceed to Checkout'),
          ),
        ],
      ),
    );
  }
}