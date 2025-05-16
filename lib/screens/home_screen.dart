import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/item_provider.dart';
import 'package:campus_care/screens/login_screen.dart';
import 'package:campus_care/screens/staff/staff_dashboard.dart';
import 'package:campus_care/widgets/item_card.dart';
import 'package:campus_care/widgets/category_filter.dart';
import 'package:campus_care/screens/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated) {
        itemProvider.loadItems();
        
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
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Care'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authProvider.signOut();
              },
            ),
        ],
      ),
      body: authProvider.isAuthenticated
          ? _buildAuthenticatedContent(itemProvider)
          : _buildUnauthenticatedContent(),
    );
  }

  Widget _buildAuthenticatedContent(ItemProvider itemProvider) {
    if (itemProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (itemProvider.error != null) {
      return Center(
        child: Text(
          'Error: ${itemProvider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    
    if (itemProvider.items.isEmpty) {
      return const Center(
        child: Text('No items available'),
      );
    }
    
    return Column(
      children: [
        const CategoryFilter(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: itemProvider.items.length,
            itemBuilder: (context, index) {
              final item = itemProvider.items[index];
              return ItemCard(item: item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to Campus Care',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please login to continue',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}