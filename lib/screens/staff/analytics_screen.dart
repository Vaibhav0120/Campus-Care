import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/services/order_service.dart';
import 'package:fl_chart/fl_chart.dart'; // You'll need to add this package to your pubspec.yaml

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _timeRange = 'month'; // 'week', 'month', 'year'
  
  // Analytics data
  double _totalRevenue = 0;
  int _totalOrders = 0;
  Map<String, int> _itemsSold = {};
  Map<String, double> _itemRevenue = {};
  List<MapEntry<String, int>> _topSellingItems = [];
  Map<int, double> _dailyRevenue = {};

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
      
      // Filter orders based on time range
      _filterOrdersByTimeRange();
      
      // Calculate analytics
      _calculateAnalytics();
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

  void _filterOrdersByTimeRange() {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_timeRange) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = DateTime(now.year, now.month - 1, now.day);
    }
    
    _orders = _orders.where((order) => order.createdAt.isAfter(startDate)).toList();
  }

  void _calculateAnalytics() {
    // Reset values
    _totalRevenue = 0;
    _totalOrders = _orders.length;
    _itemsSold = {};
    _itemRevenue = {};
    _dailyRevenue = {};
    
    for (var order in _orders) {
      // Calculate total revenue
      _totalRevenue += order.totalPrice;
      
      // Calculate items sold and revenue per item
      for (var item in order.items) {
        final itemName = item.name;
        
        // Update items sold count
        if (_itemsSold.containsKey(itemName)) {
          _itemsSold[itemName] = _itemsSold[itemName]! + item.quantity;
        } else {
          _itemsSold[itemName] = item.quantity;
        }
        
        // Update item revenue
        final itemRevenue = item.price * item.quantity;
        if (_itemRevenue.containsKey(itemName)) {
          _itemRevenue[itemName] = _itemRevenue[itemName]! + itemRevenue;
        } else {
          _itemRevenue[itemName] = itemRevenue;
        }
      }
      
      // Calculate daily revenue
      final day = order.createdAt.day;
      if (_dailyRevenue.containsKey(day)) {
        _dailyRevenue[day] = _dailyRevenue[day]! + order.totalPrice;
      } else {
        _dailyRevenue[day] = order.totalPrice;
      }
    }
    
    // Sort items by quantity sold to get top selling items
    _topSellingItems = _itemsSold.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 5 items
    if (_topSellingItems.length > 5) {
      _topSellingItems = _topSellingItems.sublist(0, 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : _error != null
              ? _buildErrorView()
              : _buildAnalyticsView(),
    );
  }

  Widget _buildErrorView() {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    
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

  Widget _buildAnalyticsView() {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time range selector
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
                      'Time Range',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTimeRangeChip('Last Week', 'week'),
                          const SizedBox(width: 8),
                          _buildTimeRangeChip('Last Month', 'month'),
                          const SizedBox(width: 8),
                          _buildTimeRangeChip('Last Year', 'year'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Revenue',
                    '₹${_totalRevenue.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Orders',
                    _totalOrders.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
              ],
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _topSellingItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _topSellingItems.isNotEmpty
                                    ? _topSellingItems.first.value * 1.2
                                    : 10,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${_topSellingItems[groupIndex].key}\n',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: '${rod.toY.round()} sold',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value >= _topSellingItems.length || value < 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _getShortName(_topSellingItems[value.toInt()].key),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                barGroups: _topSellingItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: item.value.toDouble(),
                                        color: primaryColor,
                                        width: 20,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
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
                      'Daily Revenue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dailyRevenue.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          'Day ${spot.x.toInt()}\n',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '₹${spot.y.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '₹${value.toInt()}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                      reservedSize: 40,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade300,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _dailyRevenue.entries.map((entry) {
                                      return FlSpot(
                                        entry.key.toDouble(),
                                        entry.value,
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: primaryColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: primaryColor.withOpacity(0.2),
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
            
            // Item-wise revenue
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
                      'Item-wise Revenue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _itemRevenue.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _getItemRevenueSections(),
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    // Handle touch events if needed
                                  },
                                ),
                              ),
                            ),
                          ),
                    if (_itemRevenue.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          ..._getLegendItems(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, String value) {
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    final isSelected = _timeRange == value;
    
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
          _timeRange = value;
          _loadOrders();
        });
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortName(String name) {
    if (name.length <= 6) return name;
    return '${name.substring(0, 5)}...';
  }

  List<PieChartSectionData> _getItemRevenueSections() {
    final List<Color> colors = [
      const Color(0xFFFEC62B), // Primary color
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    
    // Calculate total revenue for percentage
    final totalRevenue = _itemRevenue.values.fold(0.0, (sum, value) => sum + value);
    
    // Sort items by revenue
    final sortedItems = _itemRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 6 items, group the rest as "Others"
    List<MapEntry<String, double>> topItems = [];
    double othersRevenue = 0.0;
    
    for (int i = 0; i < sortedItems.length; i++) {
      if (i < 6) {
        topItems.add(sortedItems[i]);
      } else {
        othersRevenue += sortedItems[i].value;
      }
    }
    
    // Add "Others" if needed
    if (othersRevenue > 0) {
      topItems.add(MapEntry('Others', othersRevenue));
    }
    
    // Create pie chart sections
    return topItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = (item.value / totalRevenue) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: item.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _getLegendItems() {
    final List<Color> colors = [
      const Color(0xFFFEC62B), // Primary color
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    
    // Sort items by revenue
    final sortedItems = _itemRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 6 items, group the rest as "Others"
    List<MapEntry<String, double>> topItems = [];
    double othersRevenue = 0.0;
    
    for (int i = 0; i < sortedItems.length; i++) {
      if (i < 6) {
        topItems.add(sortedItems[i]);
      } else {
        othersRevenue += sortedItems[i].value;
      }
    }
    
    // Add "Others" if needed
    if (othersRevenue > 0) {
      topItems.add(MapEntry('Others', othersRevenue));
    }
    
    return topItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '₹${item.value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}