import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../routes/app_routes.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardBlack,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          _buildTile(context, Icons.dashboard, 'Dashboard', AppRoutes.adminDashboard),
          _buildTile(context, Icons.people, 'Customers', AppRoutes.customerList),
          _buildTile(context, Icons.store, 'Vendors', AppRoutes.vendorList),
          _buildTile(context, Icons.add_business, 'Add Vendor', AppRoutes.addVendor),
          _buildTile(context, Icons.delivery_dining, 'Riders', AppRoutes.riderList),
          _buildTile(context, Icons.person_add, 'Add Rider', AppRoutes.addRider),
          Divider(color: AppColors.richGold.withOpacity(0.3)),
          _buildTile(context, Icons.category, 'Categories', AppRoutes.viewCategories),
          _buildTile(context, Icons.add_circle, 'Add Category', AppRoutes.addCategory),
          _buildTile(context, Icons.branding_watermark, 'Brands', AppRoutes.viewBrands),
          _buildTile(context, Icons.add_box, 'Add Brand', AppRoutes.addBrand),
          _buildTile(context, Icons.approval, 'Product Approval', AppRoutes.productApproval),
          Divider(color: AppColors.richGold.withOpacity(0.3)),
          _buildTile(context, Icons.shopping_bag, 'Order Manager', AppRoutes.adminOrderManager),
          _buildTile(context, Icons.pending_actions, 'Ready Orders', AppRoutes.adminReadyOrders),
          Divider(color: AppColors.richGold.withOpacity(0.3)),
          _buildTile(context, Icons.feedback, 'Feedback', AppRoutes.adminFeedback),
          _buildTile(context, Icons.star_rate, 'Reviews', AppRoutes.adminReviewManagement),
          _buildTile(context, Icons.account_balance_wallet, 'Withdrawal Requests', AppRoutes.adminWithdrawals),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lightGold, AppColors.richGold],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.admin_panel_settings, color: AppColors.deepBlack, size: 48),
          SizedBox(height: 8),
          Text(
            'Admin Panel',
            style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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