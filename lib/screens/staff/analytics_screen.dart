import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/services/order_service.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/item_provider.dart';
import 'package:campus_care/providers/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final OrderService _orderService = OrderService();
  
  bool _isLoading = false;
  String? _error;
  
  List<OrderModel> _orders = [];
  List<ItemModel> _items = [];
  
  // Analytics data
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;
  List<MapEntry<String, int>> _topSellingItems = [];
  
  // Revenue data for chart
  List<FlSpot> _revenueData = [];
  double _maxRevenue = 0;
  
  // Date range
  String _dateRange = 'week'; // 'week', 'month', 'year'
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Load orders using the existing OrderService
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orders = await _orderService.getOrders(
        authProvider.user!.id,
        isStaff: true,
      );
      
      // Load items using the ItemProvider
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      await itemProvider.loadItems(onlyAvailable: false);
      final items = itemProvider.items;
      
      setState(() {
        _orders = orders;
        _items = items;
        
        // Calculate analytics
        _calculateAnalytics();
      });
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
  
  void _calculateAnalytics() {
    // Filter orders based on date range
    final filteredOrders = _filterOrdersByDateRange(_orders);
    
    // Calculate total revenue
    _totalRevenue = filteredOrders.fold(0, (sum, order) {
      // Calculate total from order items
      final orderTotal = order.items.fold(0.0, (itemSum, item) {
        return itemSum + (item.quantity * item.price);
      });
      return sum + orderTotal;
    });
    
    // Calculate total orders
    _totalOrders = filteredOrders.length;
    
    // Calculate average order value
    _averageOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
    
    // Calculate top selling items
    final itemQuantityMap = <String, int>{};
    
    for (final order in filteredOrders) {
      for (final item in order.items) {
        final itemId = item.itemId;
        itemQuantityMap[itemId] = (itemQuantityMap[itemId] ?? 0) + item.quantity;
      }
    }
    
    // Convert to list and sort
    final sortedItems = itemQuantityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Get top 5 items with names
    _topSellingItems = sortedItems.take(5).map((entry) {
      final item = _items.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => ItemModel(
          id: entry.key,
          name: 'Unknown Item',
          price: 0,
          availableToday: false,
          createdAt: DateTime.now(),
        ),
      );
      
      return MapEntry(item.name, entry.value);
    }).toList();
    
    // Calculate revenue data for chart
    _calculateRevenueData(filteredOrders);
  }
  
  List<OrderModel> _filterOrdersByDateRange(List<OrderModel> orders) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_dateRange) {
      case 'week':
        // Start from 7 days ago
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        // Start from 30 days ago
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        // Start from 365 days ago
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }
    
    return orders.where((order) => order.createdAt.isAfter(startDate)).toList();
  }
  
  void _calculateRevenueData(List<OrderModel> orders) {
    final now = DateTime.now();
    final Map<String, double> revenueByDate = {};
    
    // Initialize with zero values
    if (_dateRange == 'week') {
      // For week, show last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('MM/dd').format(date);
        revenueByDate[dateStr] = 0;
      }
    } else if (_dateRange == 'month') {
      // For month, show last 30 days grouped by week
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: i * 7 + 6));
        final weekEnd = now.subtract(Duration(days: i * 7));
        final dateStr = '${DateFormat('MM/dd').format(weekStart)}-${DateFormat('MM/dd').format(weekEnd)}';
        revenueByDate[dateStr] = 0;
      }
    } else if (_dateRange == 'year') {
      // For year, show last 12 months
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final dateStr = DateFormat('MMM').format(date);
        revenueByDate[dateStr] = 0;
      }
    }
    
    // Calculate revenue for each date
    for (final order in orders) {
      final orderDate = order.createdAt;
      String? dateKey;
      
      if (_dateRange == 'week') {
        dateKey = DateFormat('MM/dd').format(orderDate);
      } else if (_dateRange == 'month') {
        // Find which week this order belongs to
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: i * 7 + 6));
          final weekEnd = now.subtract(Duration(days: i * 7));
          if (orderDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
              orderDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
            dateKey = '${DateFormat('MM/dd').format(weekStart)}-${DateFormat('MM/dd').format(weekEnd)}';
            break;
          }
        }
        if (dateKey == null) continue; // Skip if not in any week
      } else {
        dateKey = DateFormat('MMM').format(orderDate);
      }
      
      if (revenueByDate.containsKey(dateKey)) {
        // Calculate order total
        final orderTotal = order.items.fold(0.0, (sum, item) {
          return sum + (item.quantity * item.price);
        });
        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) + orderTotal;
      }
    }
    
    // Convert to FlSpot list
    _revenueData = [];
    int index = 0;
    _maxRevenue = 0;
    
    for (final entry in revenueByDate.entries) {
      _revenueData.add(FlSpot(index.toDouble(), entry.value));
      if (entry.value > _maxRevenue) {
        _maxRevenue = entry.value;
      }
      index++;
    }
    
    // Ensure we have a non-zero max for the chart
    if (_maxRevenue == 0) {
      _maxRevenue = 100;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;
    
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
              onPressed: _loadData,
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
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: isLargeScreen
            ? _buildLargeScreenLayout(primaryColor)
            : _buildSmallScreenLayout(primaryColor),
      ),
    );
  }
  
  Widget _buildLargeScreenLayout(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildDateRangeSelector(primaryColor),
            ],
          ),
          const SizedBox(height: 24),
          
          // Summary cards
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(2)}', Icons.attach_money, primaryColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Total Orders', _totalOrders.toString(), Icons.shopping_bag, primaryColor)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Average Order', '₹${_averageOrderValue.toStringAsFixed(2)}', Icons.trending_up, primaryColor)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue chart
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue Trend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dateRangeText(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: _buildRevenueChart(primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Top selling items
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top Selling Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._topSellingItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _buildTopSellingItem(index, item.key, item.value, primaryColor);
                        }),
                        if (_topSellingItems.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No sales data available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Additional analytics section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales by Item Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildCategoryChart(primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSmallScreenLayout(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date range selector
          _buildDateRangeSelector(primaryColor),
          const SizedBox(height: 16),
          
          // Summary cards - stacked for mobile
          _buildSummaryCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(2)}', Icons.attach_money, primaryColor),
          const SizedBox(height: 12),
          _buildSummaryCard('Total Orders', _totalOrders.toString(), Icons.shopping_bag, primaryColor),
          const SizedBox(height: 12),
          _buildSummaryCard('Average Order', '₹${_averageOrderValue.toStringAsFixed(2)}', Icons.trending_up, primaryColor),
          const SizedBox(height: 24),
          
          // Revenue chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dateRangeText(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildRevenueChart(primaryColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Top selling items
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Selling Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._topSellingItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildTopSellingItem(index, item.key, item.value, primaryColor);
                  }),
                  if (_topSellingItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No sales data available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales by Item Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildCategoryChart(primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color primaryColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateRangeSelector(Color primaryColor) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateRangeButton('Week', 'week', primaryColor),
            _buildDateRangeButton('Month', 'month', primaryColor),
            _buildDateRangeButton('Year', 'year', primaryColor),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateRangeButton(String label, String value, Color primaryColor) {
    final isSelected = _dateRange == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _dateRange = value;
          _calculateAnalytics();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  String _dateRangeText() {
    final now = DateTime.now();
    
    switch (_dateRange) {
      case 'week':
        final startDate = now.subtract(const Duration(days: 6));
        return 'Last 7 days (${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(now)})';
      case 'month':
        final startDate = now.subtract(const Duration(days: 29));
        return 'Last 30 days (${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(now)})';
      case 'year':
        final startDate = now.subtract(const Duration(days: 364));
        return 'Last 12 months (${DateFormat('MMM yyyy').format(startDate)} - ${DateFormat('MMM yyyy').format(now)})';
      default:
        return '';
    }
  }
  
  Widget _buildRevenueChart(Color primaryColor) {
    if (_revenueData.isEmpty) {
      return Center(
        child: Text(
          'No revenue data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _maxRevenue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _revenueData.length) {
                  String label = '';
                  if (_dateRange == 'week') {
                    final now = DateTime.now();
                    final date = now.subtract(Duration(days: 6 - value.toInt()));
                    label = DateFormat('E').format(date);
                  } else if (_dateRange == 'month') {
                    final weekIndex = value.toInt();
                    label = 'W${4 - weekIndex}';
                  } else {
                    final now = DateTime.now();
                    final month = now.month - value.toInt();
                    final date = DateTime(now.year, month, 1);
                    label = DateFormat('MMM').format(date);
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _maxRevenue / 5,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: _revenueData.length - 1.0,
        minY: 0,
        maxY: _maxRevenue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: _revenueData,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopSellingItem(int index, String name, int quantity, Color primaryColor) {
    final maxQuantity = _topSellingItems.isNotEmpty 
        ? _topSellingItems.map((e) => e.value).reduce((a, b) => a > b ? a : b) 
        : 0;
    
    final progress = maxQuantity > 0 ? quantity / maxQuantity : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}. $name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$quantity sold',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.toDouble(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
  
  // Replace the _buildCategoryChart method with this implementation that infers categories from item names
  Widget _buildCategoryChart(Color primaryColor) {
    if (_orders.isEmpty || _items.isEmpty) {
      return Center(
        child: Text(
          'No sales data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }
    
    // Infer categories from item names
    final Map<String, double> categoryRevenue = {};
    
    // Helper function to infer category from item name
    String inferCategory(String itemName) {
      itemName = itemName.toLowerCase();
      
      if (itemName.contains('coffee') || itemName.contains('tea') || 
          itemName.contains('juice') || itemName.contains('water') || 
          itemName.contains('soda') || itemName.contains('drink')) {
        return 'Beverages';
      } else if (itemName.contains('sandwich') || itemName.contains('burger') || 
                 itemName.contains('wrap') || itemName.contains('roll')) {
        return 'Sandwiches & Wraps';
      } else if (itemName.contains('pizza') || itemName.contains('pasta') || 
                 itemName.contains('noodle')) {
        return 'Italian & Noodles';
      } else if (itemName.contains('rice') || itemName.contains('biryani') || 
                 itemName.contains('curry') || itemName.contains('thali')) {
        return 'Indian Meals';
      } else if (itemName.contains('cake') || itemName.contains('pastry') || 
                 itemName.contains('cookie') || itemName.contains('sweet') || 
                 itemName.contains('ice cream') || itemName.contains('dessert')) {
        return 'Desserts';
      } else if (itemName.contains('chips') || itemName.contains('fries') || 
                 itemName.contains('snack') || itemName.contains('popcorn')) {
        return 'Snacks';
      } else {
        return 'Others';
      }
    }
    
    // Calculate revenue by inferred category
    for (final order in _orders) {
      for (final orderItem in order.items) {
        // Find the item details
        final item = _items.firstWhere(
          (item) => item.id == orderItem.itemId,
          orElse: () => ItemModel(
            id: orderItem.itemId,
            name: 'Unknown Item',
            price: 0,
            availableToday: false,
            createdAt: DateTime.now(),
          ),
        );
        
        final category = inferCategory(item.name);
        final revenue = orderItem.quantity * orderItem.price;
        
        categoryRevenue[category] = (categoryRevenue[category] ?? 0) + revenue;
      }
    }
    
    // Sort categories by revenue
    final sortedCategories = categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Prepare data for the chart
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      primaryColor,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    
    double totalRevenue = categoryRevenue.values.fold(0, (sum, value) => sum + value);
    
    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = totalRevenue > 0 ? (entry.value / totalRevenue) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final revenue = entry.value.value;
            final color = colors[index % colors.length];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$category: ₹${revenue.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
