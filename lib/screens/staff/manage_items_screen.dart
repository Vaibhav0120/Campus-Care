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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false)
          .loadItems(onlyAvailable: false);
    });
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

    await showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(builder: (stateContext, setState) {
        return AlertDialog(
          title: Text(item == null ? 'Add Item' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '₹',
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
                  Row(
                    children: [
                      const Text('Available Today:'),
                      const Spacer(),
                      Switch(
                        value: availableToday,
                        onChanged: (value) {
                          setState(() {
                            availableToday = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image preview section
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : kIsWeb
                            ? webImage != null
                                ? Image.memory(
                                    webImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          'Error loading web image: $error');
                                      return const Icon(
                                          Icons.image_not_supported,
                                          size: 50);
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
                                          return const Icon(
                                              Icons.image_not_supported,
                                              size: 50);
                                        },
                                      )
                                    : const Center(
                                        child: Text('No image selected'))
                            : pickedImage != null
                                ? Image.file(
                                    File(pickedImage!.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          'Error loading file image: $error');
                                      return const Icon(
                                          Icons.image_not_supported,
                                          size: 50);
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
                                          return const Icon(
                                              Icons.image_not_supported,
                                              size: 50);
                                        },
                                      )
                                    : const Center(
                                        child: Text('No image selected')),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: isUploading
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
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
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
                            // Fixed: Added null check with ! operator
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
              child: Text(item == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    if (itemProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (itemProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${itemProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => itemProvider.loadItems(onlyAvailable: false),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: itemProvider.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No items available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddEditItemDialog(context),
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: itemProvider.items.length,
              itemBuilder: (context, index) {
                final item = itemProvider.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading item image: $error');
                                return const Icon(Icons.fastfood, size: 50);
                              },
                            ),
                          )
                        : const Icon(Icons.fastfood, size: 50),
                    title: Text(item.name),
                    subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.availableToday,
                          onChanged: (value) {
                            itemProvider.toggleItemAvailability(item.id, value);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showAddEditItemDialog(context, item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}