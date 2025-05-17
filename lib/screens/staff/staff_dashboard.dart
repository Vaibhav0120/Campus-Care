import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/screens/login_screen.dart';
import 'package:campus_care/screens/staff/manage_items_screen.dart';
import 'package:campus_care/services/order_service.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/widgets/order_tile.dart';
import 'package:campus_care/config/supabase_config.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  List<OrderModel> _pendingOrders = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingOrders();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _unsubscribeFromOrders();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToOrders() {
    try {
      final supabase = SupabaseConfig.supabaseClient;

      _ordersSubscription = supabase
          .channel('public:orders')
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'INSERT',
              schema: 'public',
              table: 'orders',
            ),
            (payload, [ref]) {
              _handleNewOrder(payload);
            },
          )
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'UPDATE',
              schema: 'public',
              table: 'orders',
            ),
            (payload, [ref]) {
              _handleOrderUpdate(payload);
            },
          );
      
      // Subscribe to the channel (subscribe() returns void)
      _ordersSubscription?.subscribe();

      debugPrint('Subscribed to orders channel');
    } catch (e) {
      debugPrint('Error subscribing to orders: $e');
    }
  }

  void _unsubscribeFromOrders() {
    try {
      _ordersSubscription?.unsubscribe();
      debugPrint('Unsubscribed from orders channel');
    } catch (e) {
      debugPrint('Error unsubscribing from orders: $e');
    }
  }

  void _handleNewOrder(Map<String, dynamic> payload) {
    try {
      final newOrderData = payload['new'];
      if (newOrderData != null && newOrderData['status'] == 'pending') {
        final newOrder = OrderModel.fromJson(newOrderData);

        setState(() {
          // Add the new order to the list if it's not already there
          if (!_pendingOrders.any((order) => order.id == newOrder.id)) {
            _pendingOrders.add(newOrder);
          }
        });

        // Show a notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New order received!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                _tabController.animateTo(0); // Switch to pending orders tab
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling new order: $e');
    }
  }

  void _handleOrderUpdate(Map<String, dynamic> payload) {
    try {
      final updatedOrderData = payload['new'];
      final oldOrderData = payload['old'];

      if (updatedOrderData != null && oldOrderData != null) {
        final orderId = updatedOrderData['id'];
        final newStatus = updatedOrderData['status'];

        // If the order was marked as completed, remove it from the pending list
        if (newStatus == 'completed' && oldOrderData['status'] == 'pending') {
          setState(() {
            _pendingOrders.removeWhere((order) => order.id == orderId);
          });
        }
      }
    } catch (e) {
      debugPrint('Error handling order update: $e');
    }
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _pendingOrders = await _orderService.getPendingOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markOrderAsCompleted(String orderId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _orderService.markOrderAsCompleted(orderId);

      if (success) {
        setState(() {
          _pendingOrders.removeWhere((order) => order.id == orderId);
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = provider_pkg.Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated || !authProvider.isStaff) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'You need to be logged in as staff to access this page',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Orders'),
            Tab(text: 'Manage Items'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingOrdersTab(),
          const ManageItemsScreen(),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No pending orders',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Text(
              'New orders will appear here automatically',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingOrders.length,
        itemBuilder: (context, index) {
          final order = _pendingOrders[index];
          return OrderTile(
            order: order,
            isStaff: true,
            onMarkCompleted: () => _markOrderAsCompleted(order.id),
          );
        },
      ),
    );
  }
}
