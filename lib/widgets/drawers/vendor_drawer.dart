import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../routes/app_routes.dart';

class VendorDrawer extends StatelessWidget {
  const VendorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardBlack,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.lightGold, AppColors.richGold],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.store, color: AppColors.deepBlack, size: 48),
                SizedBox(height: 8),
                Text(
                  'Vendor Panel',
                  style: TextStyle(
                    color: AppColors.deepBlack,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildTile(context, Icons.dashboard, 'Dashboard', AppRoutes.vendorDashboard),
          _buildTile(context, Icons.add_box, 'Add Product', AppRoutes.addProduct),
          _buildTile(context, Icons.list, 'My Products', AppRoutes.listProduct),
          _buildTile(context, Icons.shopping_bag, 'Orders', AppRoutes.vendorOrders),
          _buildTile(context, Icons.star, 'Reviews', AppRoutes.vendorReviews),
          _buildTile(context, Icons.account_balance_wallet, 'Earnings', AppRoutes.vendorEarnings),
        ],
      ),
    );
  }

  ListTile _buildTile(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.richGold),
      title: Text(title, style: TextStyle(color: AppColors.lightGold)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}