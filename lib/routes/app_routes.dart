import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ================= SCREENS =================
// ADMIN
import 'package:mobileapp/admin/AdminOrderManagerScreen.dart';
import 'package:mobileapp/admin/admin_ready_orders_screen.dart';
import 'package:mobileapp/admin/admin_review_management_screen.dart';
import 'package:mobileapp/admin/admin_withdrawal_management_screen.dart';
import 'package:mobileapp/admin/assign_rider_screen.dart';
import 'package:mobileapp/admin/dashboard_screen.dart';
import 'package:mobileapp/admin/add_vendor_screen.dart';
import 'package:mobileapp/admin/vendor_list_screen.dart';
import 'package:mobileapp/admin/customer_list_screen.dart';
import 'package:mobileapp/admin/add_category_screen.dart';
import 'package:mobileapp/admin/ViewCategories.dart';
import 'package:mobileapp/admin/add_brand_screen.dart';
import 'package:mobileapp/admin/brandlist.dart';
import 'package:mobileapp/admin/product_approve.dart';
import 'package:mobileapp/admin/add_rider_screen.dart';
import 'package:mobileapp/admin/rider_list_screen.dart';
import 'package:mobileapp/admin/admin_feedback_screen.dart';
import 'package:mobileapp/common/navbar.dart';

// RIDER
import 'package:mobileapp/rider/rider_dashboard.dart' hide AssignRiderScreen;
import 'package:mobileapp/rider/rider_earnings_screen.dart';
import 'package:mobileapp/rider/rider_orders_screen.dart';
import 'package:mobileapp/rider/rider_profile_screen.dart';

// VENDOR
import 'package:mobileapp/vendor/vendor_dashboard_screen.dart';
import 'package:mobileapp/vendor/vendor_add_product.dart';
import 'package:mobileapp/vendor/vendor_earnings_screen.dart';
import 'package:mobileapp/vendor/vendor_product_list_screen.dart';
import 'package:mobileapp/vendor/vendor_orders_screen.dart';
import 'package:mobileapp/vendor/vendor_review_management_screen.dart';

// CUSTOMER
import 'package:mobileapp/customer/home_screen.dart';
import 'package:mobileapp/customer/user_orders_screen.dart';
import 'package:mobileapp/customer/order_tracking_screen.dart';
import 'package:mobileapp/customer/customer_contact_form.dart';
import 'package:mobileapp/customer/product_list_screen.dart';
import 'package:mobileapp/customer/ChatBotScreen.dart';
import 'package:mobileapp/customer/CustomerProfileScreen.dart';
import 'package:mobileapp/customer/WishlistScreen.dart';
import 'package:mobileapp/customer/search_result_screen.dart';
import 'package:mobileapp/models/order_model.dart'; // 🆕 ADD THIS IMPORT
import 'package:mobileapp/constants/colors.dart' hide AppColors; // 🆕 ADD THIS IMPORT

// AUTH
import 'package:mobileapp/common/splash_screen.dart';
import 'package:mobileapp/screens/auth/login_screen.dart';
import 'package:mobileapp/screens/auth/signup_screen.dart';
import 'package:mobileapp/widgets/sheets/customer_notification_sheet.dart';

class AppRoutes {
  // -------- AUTH --------
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';

  // -------- DASHBOARDS --------
  static const home = '/home';
  static const customerHome = '/customer_home';
  static const vendorDashboard = '/vendor_dashboard';
  static const adminDashboard = '/admin_dashboard';

  // -------- ADMIN --------
  static const vendorList = '/vendor_list';
  static const addVendor = '/add_vendor';
  static const customerList = '/customer_list';
  static const addCategory = '/add_category';
  static const viewCategories = '/view_categories';
  static const addBrand = '/add_brand';
  static const viewBrands = '/view_brands';
  static const productApproval = '/product_approval';
  static const adminReadyOrders = '/admin_ready_orders';
  static const assignRider = '/assign_rider';
  static const adminOrderManager = '/admin_order_manager';
  static const adminFeedback = '/admin_feedback';
  static const adminReviewManagement = '/admin_reviews';
  static const adminWithdrawals = '/admin_withdrawals';

  // -------- RIDER --------
  static const addRider = '/add_rider';
  static const riderList = '/rider_list';
  static const riderDashboard = '/rider_dashboard';
  static const riderOrders = '/rider_orders';
  static const riderProfile = '/rider_profile';
  static const riderEarnings = '/rider_earnings';

  // -------- VENDOR --------
  static const addProduct = '/add_product';
  static const listProduct = '/list_product';
  static const vendorOrders = '/vendor_orders';
  static const vendorReviews = '/vendor_reviews';
  static const vendorEarnings = '/vendor_earnings';

  // -------- CUSTOMER --------
  static const cart = '/cart';
  static const myOrders = '/my_orders';
  static const orderTracking = '/order_tracking';
  static const allProducts = '/all_products';
  static const customerContactForm = '/contact_form';
  static const chatBot = '/chatbot';
  static const customerProfile = '/customer_profile';
  static const wishlist = '/wishlist';
  static const search = '/search';
  static const customerNotifications = '/customer-notifications'; // 🆕 NOTIFICATION ROUTE

  // ================= ROUTES MAP =================
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // AUTH
      splash: (context) => SplashScreen(),
      login: (context) => LoginScreen(),
      signup: (context) => SignupScreen(),

      // DASHBOARDS
      home: (context) => RoleBasedNav(role: UserRole.customer, child: HomeScreen()),
      customerHome: (context) => RoleBasedNav(role: UserRole.customer, child: HomeScreen()),
      vendorDashboard: (context) => RoleBasedNav(role: UserRole.vendor, child: VendorDashboardScreen()),
      adminDashboard: (context) => RoleBasedNav(role: UserRole.admin, child: AdminDashboardScreen()),

      // ADMIN
      vendorList: (context) => RoleBasedNav(role: UserRole.admin, child: VendorListScreen()),
      addVendor: (context) => RoleBasedNav(role: UserRole.admin, child: AddVendorScreen()),
      customerList: (context) => RoleBasedNav(role: UserRole.admin, child: CustomerListScreen()),
      addCategory: (context) => RoleBasedNav(role: UserRole.admin, child: AddCategoryScreen()),
      viewCategories: (context) => RoleBasedNav(role: UserRole.admin, child: ViewCategoriesScreen()),
      addBrand: (context) => RoleBasedNav(role: UserRole.admin, child: AddBrandScreen()),
      viewBrands: (context) => RoleBasedNav(role: UserRole.admin, child: ViewBrandsScreen()),
      productApproval: (context) => RoleBasedNav(role: UserRole.admin, child: ProductApprovalScreen()),
      adminReadyOrders: (context) => RoleBasedNav(role: UserRole.admin, child: AdminReadyOrdersScreen()),
      assignRider: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args == null || args is! String) {
          return Scaffold(body: Center(child: Text('Invalid order ID')));
        }
        return RoleBasedNav(role: UserRole.admin, child: AssignRiderScreen(orderId: args));
      },
      adminOrderManager: (context) => RoleBasedNav(role: UserRole.admin, child: AdminOrderManagerScreen()),
      adminFeedback: (context) => RoleBasedNav(role: UserRole.admin, child: AdminFeedbackScreen()),
      adminReviewManagement: (context) => RoleBasedNav(role: UserRole.admin, child: AdminReviewManagementScreen()),
      adminWithdrawals: (context) => RoleBasedNav(role: UserRole.admin, child: AdminWithdrawalManagementScreen()),

      // RIDER
      addRider: (context) => RoleBasedNav(role: UserRole.admin, child: AddRiderScreen()),
      riderList: (context) => RoleBasedNav(role: UserRole.admin, child: RiderListScreen()),
      riderDashboard: (context) => RoleBasedNav(role: UserRole.rider, child: RiderDashboard()),
      riderOrders: (context) => RoleBasedNav(role: UserRole.rider, child: RiderOrdersScreen()),
      riderProfile: (context) => RoleBasedNav(role: UserRole.rider, child: RiderProfileScreen()),
      riderEarnings: (context) => RoleBasedNav(role: UserRole.rider, child: RiderEarningsScreen()),

      // VENDOR
      addProduct: (context) => RoleBasedNav(role: UserRole.vendor, child: AddProductScreen(productId: '', existingData: {})),
      listProduct: (context) => RoleBasedNav(role: UserRole.vendor, child: VendorProductListScreen()),
      vendorOrders: (context) => RoleBasedNav(role: UserRole.vendor, child: VendorOrdersScreen()),
      vendorReviews: (context) => RoleBasedNav(role: UserRole.vendor, child: VendorReviewManagementScreen()),
      vendorEarnings: (context) => RoleBasedNav(role: UserRole.vendor, child: VendorEarningsScreen()),

      // CUSTOMER
      myOrders: (context) => RoleBasedNav(role: UserRole.customer, child: UserOrdersScreen()),
      allProducts: (context) => RoleBasedNav(role: UserRole.customer, child: AllProductsScreen()),
      customerContactForm: (context) => RoleBasedNav(role: UserRole.customer, child: CustomerContactForm()),
      chatBot: (context) => RoleBasedNav(role: UserRole.customer, child: ChatbotScreen()),
      customerProfile: (context) => RoleBasedNav(role: UserRole.customer, child: SettingsScreen()),
      wishlist: (context) => RoleBasedNav(role: UserRole.customer, child: WishlistScreen()),
      search: (context) => RoleBasedNav(role: UserRole.customer, child: SearchScreen()),
      
      // 🆕 NOTIFICATIONS ROUTE
      customerNotifications: (context) => RoleBasedNav(
        role: UserRole.customer,
        child: CustomerNotificationsScreen(),
      ),

      // ORDER TRACKING WITH ARGUMENTS
      orderTracking: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        
        // Handle both OrderModel and String (orderId) arguments
        if (args is OrderModel) {
          return RoleBasedNav(
            role: UserRole.customer,
            child: OrderTrackingScreen(order: args),
          );
        } else if (args is String) {
          // If just orderId is passed, fetch the order from Firestore
          return RoleBasedNav(
            role: UserRole.customer,
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('orders').doc(args).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: AppColors.deepBlack,
                    body: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Scaffold(
                    backgroundColor: AppColors.deepBlack,
                    body: Center(
                      child: Text('Order not found', style: TextStyle(color: AppColors.lightGold)),
                    ),
                  );
                }
                final order = OrderModel.fromFirestore(snapshot.data!);
                return OrderTrackingScreen(order: order);
              },
            ),
          );
        } else if (args is Map<String, dynamic> && args.containsKey('orderId')) {
          // Handle map with orderId
          final orderId = args['orderId'] as String;
          return RoleBasedNav(
            role: UserRole.customer,
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: AppColors.deepBlack,
                    body: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Scaffold(
                    backgroundColor: AppColors.deepBlack,
                    body: Center(
                      child: Text('Order not found', style: TextStyle(color: AppColors.lightGold)),
                    ),
                  );
                }
                final order = OrderModel.fromFirestore(snapshot.data!);
                return OrderTrackingScreen(order: order);
              },
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColors.deepBlack,
          body: Center(
            child: Text('Invalid order data', style: TextStyle(color: AppColors.lightGold)),
          ),
        );
      },
    };
  }
}