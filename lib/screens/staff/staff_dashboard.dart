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
import 'package:campus_care/screens/staff/staff_order_history_screen.dart';
import 'package:campus_care/screens/staff/analytics_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this); // Updated to 4 tabs
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
      
      // Subscribe to the channel
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
        if (mounted) {
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
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color

    if (!authProvider.isAuthenticated || !authProvider.isStaff) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.6),
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
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 80,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Staff Access Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You need to be logged in as staff to access this page',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black87,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.pending_actions),
                  text: 'Pending',
                ),
                Tab(
                  icon: Icon(Icons.history),
                  text: 'History',
                ),
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Analytics',
                ),
                Tab(
                  icon: Icon(Icons.restaurant_menu),
                  text: 'Menu',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingOrdersTab(),
                const StaffOrderHistoryScreen(),
                const AnalyticsScreen(),
                const ManageItemsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersTab() {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_error != null) {
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
              'Error: $_error',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPendingOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No pending orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'New orders will appear here automatically',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadPendingOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
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

    return RefreshIndicator(
      onRefresh: _loadPendingOrders,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingOrders.length,
        itemBuilder: (context, index) {
          final order = _pendingOrders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                OrderTile(
                  order: order,
                  isStaff: true,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _markOrderAsCompleted(order.id),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}