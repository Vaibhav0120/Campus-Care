import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/providers/item_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({Key? key}) : super(key: key);

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false)
          .loadItems(onlyAvailable: false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddEditItemDialog(BuildContext context,
      [ItemModel? item]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    bool availableToday = item?.availableToday ?? true;
    XFile? pickedImage;
    String? imageUrl = item?.imageUrl;
    Uint8List? webImage;
    bool isUploading = false;
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color

    // Get screen size to adjust dialog width
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 900;
    final dialogWidth = isLargeScreen ? 500.0 : screenSize.width * 0.9;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(builder: (stateContext, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: theme.cardTheme.color,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: isLargeScreen ? 700 : screenSize.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog title
                      Text(
                        item == null ? 'Add New Item' : 'Edit Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Image preview section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: isUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: kIsWeb
                                          ? webImage != null
                                              ? Image.memory(
                                                  webImage!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    debugPrint(
                                                        'Error loading web image: $error');
                                                    return Icon(
                                                      Icons.image_not_supported,
                                                      size: 50,
                                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                    );
                                                  },
                                                )
                                              : imageUrl != null && imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (context, error, stackTrace) {
                                                        debugPrint(
                                                            'Error loading network image: $error');
                                                        return Icon(
                                                          Icons.image_not_supported,
                                                          size: 50,
                                                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                        );
                                                      },
                                                    )
                                                  : Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 50,
                                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                    )
                                          : pickedImage != null
                                              ? Image.file(
                                                  File(pickedImage!.path),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    debugPrint(
                                                        'Error loading file image: $error');
                                                    return Icon(
                                                      Icons.image_not_supported,
                                                      size: 50,
                                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                    );
                                                  },
                                                )
                                              : imageUrl != null && imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (context, error, stackTrace) {
                                                        debugPrint(
                                                            'Error loading network image: $error');
                                                        return Icon(
                                                          Icons.image_not_supported,
                                                          size: 50,
                                                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                        );
                                                      },
                                                    )
                                                  : Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 50,
                                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                    ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: isUploading
                                    ? null
                                    : () async {
                                        try {
                                          final XFile? image = await _picker.pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 1024,
                                            maxHeight: 1024,
                                            imageQuality: 85,
                                          );

                                          if (image != null) {
                                            setState(() {
                                              pickedImage = image;
                                              // For web, read the file as bytes for preview
                                              if (kIsWeb) {
                                                image.readAsBytes().then((value) {
                                                  setState(() {
                                                    webImage = value;
                                                  });
                                                });
                                              }
                                            });
                                          }
                                        } catch (e) {
                                          debugPrint('Error picking image: $e');
                                          Fluttertoast.showToast(
                                            msg: 'Error selecting image: $e',
                                            toastLength: Toast.LENGTH_LONG,
                                          );
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDarkMode ? Colors.grey[800]! : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Item name field
                      Text(
                        'Item Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter item name',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.fastfood,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.white,
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description field
                      Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Enter item description',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.white,
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Price field
                      Text(
                        'Price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        decoration: InputDecoration(
                          hintText: 'Enter price',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.currency_rupee,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.white,
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          try {
                            double.parse(value);
                          } catch (e) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Availability switch
                      SwitchListTile(
                        title: Text(
                          'Available Today',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        value: availableToday,
                        activeColor: primaryColor,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            availableToday = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setState(() {
                                        isUploading = true;
                                      });

                                      final itemProvider = Provider.of<ItemProvider>(
                                          dialogContext,
                                          listen: false);

                                      String? finalImageUrl = imageUrl;

                                      // Upload image if a new one was selected
                                      if (pickedImage != null) {
                                        try {
                                          final fileName = '${const Uuid().v4()}.jpg';
                                          debugPrint(
                                              'Uploading image: ${pickedImage!.path} as $fileName');

                                          finalImageUrl = await itemProvider.uploadImage(
                                            pickedImage!.path,
                                            fileName,
                                          );

                                          if (finalImageUrl == null) {
                                            Fluttertoast.showToast(
                                              msg:
                                                  'Failed to upload image. Please try again.',
                                              toastLength: Toast.LENGTH_LONG,
                                            );
                                            setState(() {
                                              isUploading = false;
                                            });
                                            return;
                                          }

                                          debugPrint(
                                              'Image uploaded successfully: $finalImageUrl');
                                        } catch (e) {
                                          debugPrint('Error uploading image: $e');
                                          Fluttertoast.showToast(
                                            msg: 'Error uploading image: $e',
                                            toastLength: Toast.LENGTH_LONG,
                                          );
                                          setState(() {
                                            isUploading = false;
                                          });
                                          return;
                                        }
                                      }

                                      try {
                                        if (item == null) {
                                          // Create new item
                                          final newItem = ItemModel(
                                            id: const Uuid().v4(),
                                            name: nameController.text,
                                            description: descriptionController.text,
                                            price: double.parse(priceController.text),
                                            imageUrl: finalImageUrl,
                                            availableToday: availableToday,
                                            createdAt: DateTime.now(),
                                          );

                                          final success =
                                              await itemProvider.createItem(newItem);
                                          if (success) {
                                            Fluttertoast.showToast(
                                              msg: 'Item created successfully!',
                                              toastLength: Toast.LENGTH_SHORT,
                                            );
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: 'Failed to create item. Please try again.',
                                              toastLength: Toast.LENGTH_LONG,
                                            );
                                          }
                                        } else {
                                          // Update existing item
                                          final updatedItem = item.copyWith(
                                            name: nameController.text,
                                            description: descriptionController.text,
                                            price: double.parse(priceController.text),
                                            imageUrl: finalImageUrl,
                                            availableToday: availableToday,
                                          );

                                          final success =
                                              await itemProvider.updateItem(updatedItem);
                                          if (success) {
                                            Fluttertoast.showToast(
                                              msg: 'Item updated successfully!',
                                              toastLength: Toast.LENGTH_SHORT,
                                            );
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: 'Failed to update item. Please try again.',
                                              toastLength: Toast.LENGTH_LONG,
                                            );
                                          }
                                        }

                                        // Fixed: Added mounted check before using context
                                        if (stateContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      } catch (e) {
                                        debugPrint('Error saving item: $e');
                                        Fluttertoast.showToast(
                                          msg: 'Error saving item: $e',
                                          toastLength: Toast.LENGTH_LONG,
                                        );
                                        setState(() {
                                          isUploading = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(item == null ? 'Add Item' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    const primaryColor = Color(0xFFFEC62B); // Match user home screen color
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;
    final isMediumScreen = size.width > 600 && size.width <= 900;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine grid columns based on screen size
    int crossAxisCount = 2; // Default for small screens
    if (isLargeScreen) {
      crossAxisCount = 4; // 4 columns for large screens
    } else if (isMediumScreen) {
      crossAxisCount = 3; // 3 columns for medium screens
    }

    if (itemProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (itemProvider.error != null) {
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
              'Error: ${itemProvider.error}',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => itemProvider.loadItems(onlyAvailable: false),
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

    // Filter items based on search query and availability filter
    final filteredItems = itemProvider.items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesAvailability = !_showOnlyAvailable || item.availableToday;
      
      return matchesSearch && matchesAvailability;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Search and filter bar - Responsive layout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? theme.cardTheme.color : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isLargeScreen
                        ? Row(
                            children: [
                              // Search bar
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search menu items...',
                                    hintStyle: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
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
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Filter switch
                              Expanded(
                                flex: 2,
                                child: SwitchListTile(
                                  title: Text(
                                    'Show only available items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  value: _showOnlyAvailable,
                                  activeColor: primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _showOnlyAvailable = value;
                                    });
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Refresh button
                              TextButton.icon(
                                onPressed: () => itemProvider.loadItems(onlyAvailable: false),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // Search bar
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search menu items...',
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
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
                                  });
                                },
                              ),
                              
                              // Filter switch
                              SwitchListTile(
                                title: Text(
                                  'Show only available items',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                value: _showOnlyAvailable,
                                activeColor: primaryColor,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (value) {
                                  setState(() {
                                    _showOnlyAvailable = value;
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                  
                  // Items count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${filteredItems.length} items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (!isLargeScreen)
                          TextButton.icon(
                            onPressed: () => itemProvider.loadItems(onlyAvailable: false),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Items grid - Responsive layout
                  filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.no_food,
                                  size: 80,
                                  color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No items match your search'
                                      : _showOnlyAvailable
                                          ? 'No available items'
                                          : 'No items available',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _showAddEditItemDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Add New Item'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: isLargeScreen ? 0.85 : 0.75, // Adjusted for better proportions
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return _buildItemCard(context, item, primaryColor, isDarkMode, theme);
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(context),
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item, Color primaryColor, bool isDarkMode, ThemeData theme) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;
    
    return Card(
      elevation: 4,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAddEditItemDialog(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            Stack(
              children: [
                SizedBox(
                  height: isLargeScreen ? 140 : 120, // Taller image for large screens
                  width: double.infinity,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(
                                Icons.fastfood,
                                size: 50,
                                color: isDarkMode ? Colors.grey[600] : Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.fastfood,
                            size: 50,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                ),
                // Availability badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.availableToday
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.availableToday ? 'Available' : 'Unavailable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Item details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (item.description != null && item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    // Action buttons
                    Row(
                      children: [
                        // Edit button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showAddEditItemDialog(context, item),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                            ),
                            child: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Toggle availability button
                        Container(
                          decoration: BoxDecoration(
                            color: item.availableToday ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Provider.of<ItemProvider>(context, listen: false).toggleItemAvailability(
                                item.id,
                                !item.availableToday,
                              );
                            },
                            icon: Icon(
                              item.availableToday
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: item.availableToday
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            tooltip: item.availableToday
                                ? 'Mark as unavailable'
                                : 'Mark as available',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
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
}