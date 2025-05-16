class ItemModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool availableToday;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.availableToday,
    required this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
      availableToday: json['available_today'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'available_today': availableToday,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? availableToday,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      availableToday: availableToday ?? this.availableToday,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}