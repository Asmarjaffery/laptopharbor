import 'package:flutter/material.dart';
import 'package:mobileapp/widgets/navigation/admin_scaffold.dart';
import 'package:mobileapp/widgets/navigation/customer_scaffold.dart';
import 'package:mobileapp/widgets/navigation/rider_scaffold.dart';
import 'package:mobileapp/widgets/navigation/vendor_scaffold.dart';


enum UserRole { customer, vendor, admin, rider }

class RoleBasedNav extends StatelessWidget {
  final UserRole role;
  final Widget child;

  const RoleBasedNav({super.key, required this.role, required this.child});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.customer:
        return CustomerScaffold(child: child);
      case UserRole.vendor:
        return VendorScaffold(child: child);
      case UserRole.admin:
        return AdminScaffold(child: child);
      case UserRole.rider:
        return RiderScaffold(child: child);
    }
  }
}