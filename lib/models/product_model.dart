class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int rating; // 0 to 5

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.rating = 0,
  });
}
