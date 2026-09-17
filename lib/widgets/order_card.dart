import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String productName;
  final double price;
  final String status; 
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.orderId,
    required this.productName,
    required this.price,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Product & Order Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: AppStyles.headingStyle.copyWith(fontSize: 16),
                  ),
                  Text(
                    "Order ID: $orderId",
                    style: AppStyles.bodyStyle.copyWith(color: Colors.grey),
                  ),
                  Text(
                    "\$${price.toStringAsFixed(2)}",
                    style: AppStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryColor),
                  ),
                ],
              ),
              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 6.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: AppStyles.bodyStyle.copyWith(
                      color: getStatusColor(), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
