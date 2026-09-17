import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class ReviewCard extends StatelessWidget {
  final String reviewerName;
  final String comment;
  final int rating; // 0 to 5

  const ReviewCard({
    Key? key,
    required this.reviewerName,
    required this.comment,
    this.rating = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reviewerName,
              style: AppStyles.headingStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              comment,
              style: AppStyles.bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}
