import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/screens/auth/login_screen.dart';
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

      // Create a channel for orders table
      _ordersSubscription = supabase
          .channel('orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              _handleNewOrder(payload.newRecord);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              _handleOrderUpdate({
                'new': payload.newRecord,
                'old': payload.oldRecord,
              });
            },
          )
          .subscribe();

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
      if (payload['status'] == 'pending') {
        final newOrder = OrderModel.fromJson(payload);

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
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;

    if (!authProvider.isAuthenticated || !authProvider.isStaff) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withValues(alpha: 204), // 0.8 opacity
                primaryColor.withValues(alpha: 153), // 0.6 opacity
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
                    const Icon(
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
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
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

    // Responsive layout for staff dashboard
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
      body: isLargeScreen
          ? _buildLargeScreenLayout(primaryColor)
          : _buildSmallScreenLayout(primaryColor),
    );
  }

  Widget _buildLargeScreenLayout(Color primaryColor) {
    return Row(
      children: [
        // Side navigation
        Container(
          width: 220,
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildNavItem(
                  0, 'Pending Orders', Icons.pending_actions, primaryColor),
              _buildNavItem(1, 'Order History', Icons.history, primaryColor),
              _buildNavItem(2, 'Analytics', Icons.analytics, primaryColor),
              _buildNavItem(
                  3, 'Manage Menu', Icons.restaurant_menu, primaryColor),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 26), // 0.1 opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Need help? Contact support',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Colors.grey[300],
        ),

        // Content area
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Disable swiping
            children: [
              _buildPendingOrdersTab(),
              const StaffOrderHistoryScreen(),
              const AnalyticsScreen(),
              const ManageItemsScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(Color primaryColor) {
    return Column(
      children: [
        Container(
          color: primaryColor,
          child: Theme(
            // Override the theme specifically for this TabBar
            data: ThemeData(
              tabBarTheme: const TabBarTheme(
                labelColor:
                    Colors.black, // Explicitly set selected tab text to black
                unselectedLabelColor: Colors.black54,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black, // Black indicator for visibility
              labelColor:
                  Colors.black, // Black text for selected tab (more explicit)
              unselectedLabelColor:
                  Colors.black54, // Dark text for unselected tab
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black, // Explicitly set text color in style too
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                color: Colors.black54,
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
    );
  }

  Widget _buildNavItem(
      int index, String title, IconData icon, Color primaryColor) {
    final isSelected = _tabController.index == index;

    return InkWell(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 26)
              : Colors.transparent, // 0.1 opacity
          border: Border(
            left: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.black
                  : Colors.grey[600], // Changed to black when selected
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : Colors.grey[800], // Changed to black when selected
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersTab() {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;

    if (_isLoading) {
      return const Center(
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
      child: isLargeScreen
          ? _buildLargeScreenPendingOrders()
          : _buildSmallScreenPendingOrders(),
    );
  }

  Widget _buildLargeScreenPendingOrders() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Pending Orders (${_pendingOrders.length})',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Orders grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8, // Adjusted for better fit
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _pendingOrders.length,
              itemBuilder: (context, index) {
                final order = _pendingOrders[index];
                // Add ClipRRect to ensure no overflow
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: OrderTile(
                      order: order,
                      isStaff: true,
                      onMarkCompleted: () => _markOrderAsCompleted(order.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenPendingOrders() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) {
        final order = _pendingOrders[index];
        // Add ClipRRect to ensure no overflow
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: OrderTile(
              order: order,
              isStaff: true,
              onMarkCompleted: () => _markOrderAsCompleted(order.id),
            ),
          ),
        );
      },
    );
  }
}