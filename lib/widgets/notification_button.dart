// import 'package:flutter/material.dart';
// import 'package:mobileapp/common/notifications_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:badges/badges.dart' as badges;
// import '../providers/notification_provider.dart';
// import '../constants/colors.dart';

// Widget buildNotificationButton(BuildContext context, String userId) {
//   return Consumer<NotificationProvider>(
//     builder: (context, provider, child) {
//       return badges.Badge(
//         showBadge: provider.unreadCount > 0,
//         badgeContent: Text(
//           provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
//           style: TextStyle(color: Colors.white, fontSize: 10),
//         ),
//         badgeStyle: badges.BadgeStyle(badgeColor: Colors.red, padding: EdgeInsets.all(6)),
//         child: IconButton(
//           icon: Icon(Icons.notifications_outlined, color: AppColors.richGold),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => NotificationsScreen(userId: userId)),
//             );
//           },
//         ),
//       );
//     },
//   );
// }
