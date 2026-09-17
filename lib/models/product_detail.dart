class ProductDetail {
  final String id;
  final String name;
  final double price;
  final String imageBase64;
  final int stock;
  final String description;
  final Map<String, String> specifications;

  ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.imageBase64,
    required this.stock,
    required this.description,
    required this.specifications,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // Handle specifications - it might come as Map or need to be parsed
    Map<String, String> specs = {};
    if (json['specifications'] != null) {
      if (json['specifications'] is Map) {
        json['specifications'].forEach((key, value) {
          specs[key.toString()] = value.toString();
        });
      }
    }

    return ProductDetail(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      imageBase64: json['image']?.toString() ?? json['imageBase64']?.toString() ?? '',
      stock: _parseInt(json['stock']),
      description: json['description']?.toString() ?? 'No description available',
      specifications: specs,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}