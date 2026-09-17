class Review {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String comment;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.comment,
  });
}
