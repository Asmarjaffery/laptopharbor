// lib/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'new_product', 'order_update', 'rider_assignment', 'vendor_order', 'payment'
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Extra data (orderId, productId, etc.)

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  // ============================================
  // FROM FIRESTORE
  // ============================================
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  // ============================================
  // FROM MAP
  // ============================================
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  // ============================================
  // TO MAP
  // ============================================
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  // ============================================
  // TO JSON
  // ============================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  // ============================================
  // COPY WITH
  // ============================================
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  
  // Get formatted time
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Check if notification is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // Check if notification is today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  // Get icon based on notification type
  String getIconName() {
    switch (type) {
      case 'new_product':
        return 'shopping_bag';
      case 'order_update':
        return 'local_shipping';
      case 'rider_assignment':
        return 'directions_bike';
      case 'vendor_order':
        return 'store';
      case 'payment':
        return 'payment';
      case 'promotion':
        return 'local_offer';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  // Get color based on notification type
  String getColorHex() {
    switch (type) {
      case 'new_product':
        return '#2196F3'; // Blue
      case 'order_update':
        return '#FF9800'; // Orange
      case 'rider_assignment':
        return '#4CAF50'; // Green
      case 'vendor_order':
        return '#9C27B0'; // Purple
      case 'payment':
        return '#00BCD4'; // Cyan
      case 'promotion':
        return '#FF5722'; // Deep Orange
      case 'system':
        return '#607D8B'; // Blue Grey
      default:
        return '#FFD700'; // Gold
    }
  }

  // Get priority (1 = high, 2 = medium, 3 = low)
  int get priority {
    switch (type) {
      case 'order_update':
      case 'rider_assignment':
      case 'payment':
        return 1; // High priority
      case 'new_product':
      case 'vendor_order':
        return 2; // Medium priority
      case 'promotion':
      case 'system':
        return 3; // Low priority
      default:
        return 2;
    }
  }

  // Get notification category for grouping
  String get category {
    switch (type) {
      case 'order_update':
      case 'payment':
        return 'Orders';
      case 'new_product':
      case 'promotion':
        return 'Shopping';
      case 'rider_assignment':
        return 'Deliveries';
      case 'vendor_order':
        return 'Business';
      default:
        return 'General';
    }
  }

  // Check if notification has action data
  bool get hasActionData {
    return data != null && data!.isNotEmpty;
  }

  // Get order ID from data (if exists)
  String? get orderId {
    return data?['orderId'] as String?;
  }

  // Get product ID from data (if exists)
  String? get productId {
    return data?['productId'] as String?;
  }

  // Get rider name from data (if exists)
  String? get riderName {
    return data?['riderName'] as String?;
  }

  // ============================================
  // EQUALITY & HASH CODE
  // ============================================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.isRead == isRead &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        message.hashCode ^
        type.hashCode ^
        isRead.hashCode ^
        createdAt.hashCode;
  }

  // ============================================
  // TO STRING
  // ============================================
  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, title: $title, message: $message, type: $type, isRead: $isRead, createdAt: $createdAt, data: $data)';
  }
}

// ============================================
// NOTIFICATION TYPES ENUM (Optional)
// ============================================
class NotificationType {
  static const String newProduct = 'new_product';
  static const String orderUpdate = 'order_update';
  static const String riderAssignment = 'rider_assignment';
  static const String vendorOrder = 'vendor_order';
  static const String payment = 'payment';
  static const String promotion = 'promotion';
  static const String system = 'system';
  
  static List<String> get all => [
    newProduct,
    orderUpdate,
    riderAssignment,
    vendorOrder,
    payment,
    promotion,
    system,
  ];
}

// ============================================
// USAGE EXAMPLES
// ============================================

/*
// Create new notification
final notification = NotificationModel(
  userId: 'user123',
  title: 'Order Delivered',
  message: 'Your order has been delivered successfully!',
  type: NotificationType.orderUpdate,
  createdAt: DateTime.now(),
  data: {
    'orderId': 'order123',
    'status': 'delivered',
  },
);

// Convert to map for Firestore
final notificationMap = notification.toMap();

// Create from Firestore document
final doc = await FirebaseFirestore.instance
    .collection('notifications')
    .doc('notif123')
    .get();
final notification = NotificationModel.fromFirestore(doc);

// Get formatted time
print(notification.getFormattedTime()); // "5m ago"

// Check if recent
if (notification.isRecent) {
  print('This is a recent notification');
}

// Get order ID from data
if (notification.orderId != null) {
  print('Order ID: ${notification.orderId}');
}

// Mark as read
final updatedNotification = notification.copyWith(isRead: true);
*/