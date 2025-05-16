import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/providers/item_provider.dart';

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
      Provider.of<ItemProvider>(context, listen: false).loadItems(onlyAvailable: false);
    });
  }

  Future<void> _showAddEditItemDialog(BuildContext context, [ItemModel? item]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    bool availableToday = item?.availableToday ?? true;
    String? imagePath;
    String? imageUrl = item?.imageUrl;
    
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) {
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
                    if (imagePath != null)
                      Image.file(
                        File(imagePath!),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 100,
                        ),
                      )
                    else if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 100,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        
                        if (pickedFile != null) {
                          setState(() {
                            imagePath = pickedFile.path;
                          });
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
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final itemProvider = Provider.of<ItemProvider>(dialogContext, listen: false);
                    
                    String? finalImageUrl = imageUrl;
                    
                    // Upload image if a new one was selected
                    if (imagePath != null) {
                      final fileName = '${const Uuid().v4()}.jpg';
                      finalImageUrl = await itemProvider.uploadImage(
                        imagePath!,
                        fileName,
                      );
                    }
                    
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
                      
                      await itemProvider.createItem(newItem);
                    } else {
                      // Update existing item
                      final updatedItem = item.copyWith(
                        name: nameController.text,
                        description: descriptionController.text,
                        price: double.parse(priceController.text),
                        imageUrl: finalImageUrl,
                        availableToday: availableToday,
                      );
                      
                      await itemProvider.updateItem(updatedItem);
                    }
                    
                    // Use dialogContext instead of context
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(item == null ? 'Add' : 'Save'),
              ),
            ],
          );
        }
      ),
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
                    leading: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
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
                          onPressed: () => _showAddEditItemDialog(context, item),
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