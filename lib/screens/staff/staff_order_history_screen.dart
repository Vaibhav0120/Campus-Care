import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/services/order_service.dart';
import 'package:campus_care/widgets/order_tile.dart';

class StaffOrderHistoryScreen extends StatefulWidget {
  const StaffOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StaffOrderHistoryScreen> createState() => _StaffOrderHistoryScreenState();
}

class _StaffOrderHistoryScreenState extends State<StaffOrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _filterOption = 'all'; // 'all', 'today', 'week', 'month'
  String _statusFilter = 'all'; // 'all', 'completed', 'pending'

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _orders = await _orderService.getOrders(
        authProvider.user!.id,
        isStaff: true,
      );
      
      // Apply filters
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      // First filter by date
      if (_filterOption == 'today') {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        _orders = _orders.where((order) => order.createdAt.isAfter(startOfDay)).toList();
      } else if (_filterOption == 'week') {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _orders = _orders.where((order) => order.createdAt.isAfter(startOfDay)).toList();
      } else if (_filterOption == 'month') {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        _orders = _orders.where((order) => order.createdAt.isAfter(startOfMonth)).toList();
      }
      
      // Then filter by status
      if (_statusFilter == 'completed') {
        _orders = _orders.where((order) => !order.isPending).toList();
      } else if (_statusFilter == 'pending') {
        _orders = _orders.where((order) => order.isPending).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFEC62B); // Match user home screen color
    
    return Scaffold(
      body: Column(
        children: [
          // Filter options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Date filter
                Row(
                  children: [
                    const Text('Date:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All Time', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Today', 'today'),
                            const SizedBox(width: 8),
                            _buildFilterChip('This Week', 'week'),
                            const SizedBox(width: 8),
                            _buildFilterChip('This Month', 'month'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Status filter
                Row(
                  children: [
                    const Text('Status:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Completed', 'completed'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Pending', 'pending'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Orders list
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final primaryColor = const Color(0xFFFEC62B); // Match user home screen color
    final isSelected = _filterOption == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor.withOpacity(0.2),
      checkmarkColor: Colors.black87,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.black87 : Colors.black54,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _filterOption = value;
          _loadOrders();
        });
      },
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final primaryColor = const Color(0xFFFEC62B); // Match user home screen color
    final isSelected = _statusFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor.withOpacity(0.2),
      checkmarkColor: Colors.black87,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.black87 : Colors.black54,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _loadOrders();
        });
      },
    );
  }

  Widget _buildOrdersList() {
    final primaryColor = const Color(0xFFFEC62B); // Match user home screen color
    
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
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
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
                if (order.isPending)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _orderService.markOrderAsCompleted(order.id);
                        _loadOrders();
                      },
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

  String _getEmptyStateMessage() {
    String dateMessage = '';
    String statusMessage = '';
    
    switch (_filterOption) {
      case 'today':
        dateMessage = 'today';
        break;
      case 'week':
        dateMessage = 'this week';
        break;
      case 'month':
        dateMessage = 'this month';
        break;
      default:
        dateMessage = 'in the selected time period';
    }
    
    switch (_statusFilter) {
      case 'completed':
        statusMessage = 'completed orders';
        break;
      case 'pending':
        statusMessage = 'pending orders';
        break;
      default:
        statusMessage = 'orders';
    }
    
    return 'No $statusMessage found $dateMessage.\nTry changing the filters or refresh to check again.';
  }
}