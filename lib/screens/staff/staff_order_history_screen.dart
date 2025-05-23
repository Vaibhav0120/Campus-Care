import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/services/order_service.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    List<OrderModel> filteredOrders = List.from(_orders);
    
    // First filter by date
    if (_filterOption == 'today') {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      filteredOrders = filteredOrders.where((order) => order.createdAt.isAfter(startOfDay)).toList();
    } else if (_filterOption == 'week') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      filteredOrders = filteredOrders.where((order) => order.createdAt.isAfter(startOfDay)).toList();
    } else if (_filterOption == 'month') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      filteredOrders = filteredOrders.where((order) => order.createdAt.isAfter(startOfMonth)).toList();
    }
    
    // Then filter by status
    if (_statusFilter == 'completed') {
      filteredOrders = filteredOrders.where((order) => !order.isPending).toList();
    } else if (_statusFilter == 'pending') {
      filteredOrders = filteredOrders.where((order) => order.isPending).toList();
    }
    
    // Apply search query if present
    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        // Search by order ID
        if (order.id.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return true;
        }
        
        // Search by user ID (since userName might not be available)
        if (order.userId.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return true;
        }
        
        // Search by items
        for (var item in order.items) {
          if (item.itemId.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return true;
          }
        }
        
        return false;
      }).toList();
    }
    
    setState(() {
      _orders = filteredOrders;
    });
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme, bool isDarkMode) {
    const primaryColor = Color(0xFFFEC62B);
    final isSelected = _filterOption == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black87 : isDarkMode ? theme.colorScheme.onSurface : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      checkmarkColor: Colors.black87,
      backgroundColor: isDarkMode ? theme.cardTheme.color : Colors.grey[200],
      onSelected: (selected) {
        setState(() {
          _filterOption = value;
          _loadOrders();
        });
      },
    );
  }

  Widget _buildStatusChip(String label, String value, ThemeData theme, bool isDarkMode) {
    const primaryColor = Color(0xFFFEC62B);
    final isSelected = _statusFilter == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black87 : isDarkMode ? theme.colorScheme.onSurface : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      checkmarkColor: Colors.black87,
      backgroundColor: isDarkMode ? theme.cardTheme.color : Colors.grey[200],
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _loadOrders();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Column(
        children: [
          // Header for large screens
          if (isLargeScreen)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Order History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _loadOrders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          
          // Expanded to make everything scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search orders by ID or items...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _applyFilters();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  
                  // Filter options
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? theme.cardTheme.color : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDarkMode ? 30 : 13),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isLargeScreen
                        ? Row(
                            children: [
                              // Date filter
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date Range',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildFilterChip('All Time', 'all', theme, isDarkMode),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('Today', 'today', theme, isDarkMode),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('This Week', 'week', theme, isDarkMode),
                                        const SizedBox(width: 8),
                                        _buildFilterChip('This Month', 'month', theme, isDarkMode),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 24),
                              
                              // Status filter
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildStatusChip('All', 'all', theme, isDarkMode),
                                        const SizedBox(width: 8),
                                        _buildStatusChip('Completed', 'completed', theme, isDarkMode),
                                        const SizedBox(width: 8),
                                        _buildStatusChip('Pending', 'pending', theme, isDarkMode),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter Orders',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Date filter
                              Row(
                                children: [
                                  Text(
                                    'Date:',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildFilterChip('All Time', 'all', theme, isDarkMode),
                                          const SizedBox(width: 8),
                                          _buildFilterChip('Today', 'today', theme, isDarkMode),
                                          const SizedBox(width: 8),
                                          _buildFilterChip('This Week', 'week', theme, isDarkMode),
                                          const SizedBox(width: 8),
                                          _buildFilterChip('This Month', 'month', theme, isDarkMode),
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
                                  Text(
                                    'Status:',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildStatusChip('All', 'all', theme, isDarkMode),
                                          const SizedBox(width: 8),
                                          _buildStatusChip('Completed', 'completed', theme, isDarkMode),
                                          const SizedBox(width: 8),
                                          _buildStatusChip('Pending', 'pending', theme, isDarkMode),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  
                  // Order count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${_orders.length} orders',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (!isLargeScreen)
                          TextButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Orders list
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
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
                              ),
                            )
                          : _orders.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 80,
                                          color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'No orders found',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Try changing your filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: isLargeScreen
                                      ? _buildLargeScreenOrderList(theme, isDarkMode)
                                      : _buildSmallScreenOrderList(theme, isDarkMode),
                                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenOrderList(ThemeData theme, bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          color: theme.cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID and date
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, Math.min(8, order.id.length))}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt)}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Customer info
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'User ID: ${order.userId}',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status and total
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: order.isPending ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.isPending ? 'Pending' : 'Completed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_calculateOrderTotal(order).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                Divider(
                  height: 32,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
                
                // Order items
                Text(
                  'Order Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Items table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Item ID',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    ...order.items.map((item) {
                      return TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDarkMode ? Colors.grey[800]! : Colors.grey,
                              width: 0.2,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              item.itemId,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Order actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.isPending)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final orderService = OrderService();
                          await orderService.markOrderAsCompleted(order.id);
                          _loadOrders();
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Implement order details view
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallScreenOrderList(ThemeData theme, bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          color: theme.cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Order ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, Math.min(8, order.id.length))}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: order.isPending ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.isPending ? 'Pending' : 'Completed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Customer info
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'User ID: ${order.userId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                
                Divider(
                  height: 24,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
                
                // Order items
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Item ID: ${item.itemId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                Divider(
                  height: 24,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '₹${_calculateOrderTotal(order).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Order actions
                Row(
                  children: [
                    if (order.isPending)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final orderService = OrderService();
                            await orderService.markOrderAsCompleted(order.id);
                            _loadOrders();
                          },
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Mark Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    if (order.isPending) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Implement order details view
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to calculate order total
  double _calculateOrderTotal(OrderModel order) {
    return order.items.fold(0, (sum, item) => sum + (item.quantity * item.price));
  }
}

// Import for min function
class Math {
  static int min(int a, int b) => a < b ? a : b;
}