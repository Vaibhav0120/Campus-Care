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
    final primaryColor = const Color(0xFFFEC62B); // Match user home screen color

    await showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(builder: (stateContext, setState) {
        return AlertDialog(
          title: Text(
            item == null ? 'Add New Item' : 'Edit Item',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: isUploading
                              ? Center(
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
                                                  color: Colors.grey[400],
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
                                                      color: Colors.grey[400],
                                                    );
                                                  },
                                                )
                                              : Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 50,
                                                  color: Colors.grey[400],
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
                                                  color: Colors.grey[400],
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
                                                      color: Colors.grey[400],
                                                    );
                                                  },
                                                )
                                              : Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 50,
                                                  color: Colors.grey[400],
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
                                  color: Colors.white,
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
                  const Text(
                    'Item Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter item name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.fastfood),
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
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter item description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Price field
                  const Text(
                    'Price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      hintText: 'Enter price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee),
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
                    title: const Text(
                      'Available Today',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
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
              ),
              child: Text(item == null ? 'Add Item' : 'Save Changes'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final primaryColor = const Color(0xFFFEC62B); // Match user home screen color

    if (itemProvider.isLoading) {
      return Center(
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
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                // Filter switch
                SwitchListTile(
                  title: const Text(
                    'Show only available items',
                    style: TextStyle(fontSize: 14),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Showing ${filteredItems.length} items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
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
          
          // Items list
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_food,
                          size: 80,
                          color: Colors.grey[400],
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
                            color: Colors.grey[600],
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
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        elevation: 4,
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
                                    height: 120,
                                    width: double.infinity,
                                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.fastfood,
                                              size: 50,
                                              color: Colors.grey,
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
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
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
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Edit button
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _showAddEditItemDialog(context, item),
                                              style: OutlinedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                foregroundColor: primaryColor,
                                                side: BorderSide(color: primaryColor),
                                              ),
                                              child: const Text('Edit'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Toggle availability button
                                          IconButton(
                                            onPressed: () {
                                              itemProvider.toggleItemAvailability(
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
                                            ),
                                            tooltip: item.availableToday
                                                ? 'Mark as unavailable'
                                                : 'Mark as available',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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
                    },
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
}