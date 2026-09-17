import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../routes/app_routes.dart';

class RiderDrawer extends StatelessWidget {
  const RiderDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardBlack,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          _buildTile(context, Icons.dashboard, 'Dashboard', AppRoutes.riderDashboard),
          _buildTile(context, Icons.assignment, 'My Orders', AppRoutes.riderOrders),
          _buildTile(context, Icons.account_balance_wallet, 'Earnings', AppRoutes.riderEarnings),
          _buildTile(context, Icons.person, 'Profile', AppRoutes.riderProfile),
          Divider(color: AppColors.richGold.withOpacity(0.3)),
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
          Icon(Icons.delivery_dining, color: AppColors.deepBlack, size: 48),
          SizedBox(height: 8),
          Text(
            'Rider Panel',
            style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: 22,
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
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}