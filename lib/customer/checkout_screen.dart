import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/constants/styles.dart';
import 'package:mobileapp/widgets/helpers/admin_notification_helper.dart';
import '../../constants/colors.dart';


class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final int itemCount;
  final String productId;

  const CheckoutScreen({
    Key? key,
    required this.totalAmount,
    required this.itemCount,
    required this.productId,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String selectedPaymentMethod = 'Card';
  bool _agreedToTerms = false;
  bool _isLoadingUserData = true;
  bool _isProcessingOrder = false;
  String? vendorId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchVendorId();
  }

  Future<void> _fetchVendorId() async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        setState(() {
          vendorId = productDoc['vendorId'] ?? null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product vendor info',
                style: AppStyles.bodyStyle),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _isLoadingUserData = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // ✅ UPDATED FUNCTION WITH NOTIFICATION
  Future<void> _processPayment() async {
    if (_isProcessingOrder) return;

    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please agree to terms and conditions',
              style: AppStyles.bodyStyle,
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (vendorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Product vendor information not found',
              style: AppStyles.bodyStyle,
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isProcessingOrder = true);

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          // ✅ CREATE ORDER
          final orderRef = await FirebaseFirestore.instance.collection('orders').add({
            'userId': currentUser.uid,
            'vendorId': vendorId,
            'productId': widget.productId,
            'customerName': _nameController.text.trim(),
            'customerEmail': _emailController.text.trim(),
            'customerPhone': _phoneController.text.trim(),
            'shippingAddress': _addressController.text.trim(),
            'city': _cityController.text.trim(),
            'zipCode': _zipController.text.trim(),
            'paymentMethod': selectedPaymentMethod,
            'itemCount': widget.itemCount,
            'subtotal': widget.totalAmount,
            'shippingCost': 10.0,
            'totalAmount': widget.totalAmount + 10,
            'orderStatus': 'Pending',
            'orderDate': FieldValue.serverTimestamp(),
          });

          print('✅ Order created with ID: ${orderRef.id}');

          // ✅ GET VENDOR NAME FROM FIRESTORE
          String vendorName = 'Unknown Vendor';
          try {
            DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(vendorId)
                .get();
            
            if (vendorDoc.exists) {
              final vendorData = vendorDoc.data() as Map<String, dynamic>;
              vendorName = vendorData['name'] ?? vendorData['shopName'] ?? 'Unknown Vendor';
            }
          } catch (e) {
            print('⚠️ Could not fetch vendor name: $e');
          }

          // 🔔 CREATE ADMIN NOTIFICATION
          try {
            await AdminNotificationHelper.notifyNewOrder(
              orderId: orderRef.id,
              customerName: _nameController.text.trim(),
              vendorName: vendorName,
              totalAmount: widget.totalAmount + 10,
              vendorId: vendorId,
              customerId: currentUser.uid,
            );
            print('✅ Admin notification created for order: ${orderRef.id}');
          } catch (e) {
            print('❌ Failed to create notification: $e');
            // Don't fail the order if notification fails
          }

          // Update product quantity
          DocumentSnapshot productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .get();

          if (productDoc.exists) {
            int currentQuantity = productDoc['quantity'] ?? 0;
            int newQuantity = currentQuantity - widget.itemCount;

            if (newQuantity >= 0) {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(widget.productId)
                  .update({'quantity': newQuantity});
            }
          }

          setState(() => _isProcessingOrder = false);

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.cardBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Icon(Icons.check_circle,
                    color: Colors.green, size: 60),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order Placed Successfully!',
                      style: AppStyles.subHeadingStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your order has been confirmed',
                      style: AppStyles.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order Total: \$${(widget.totalAmount + 10).toStringAsFixed(2)}',
                      style: AppStyles.cardValueStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text('OK', style: AppStyles.cardValueStyle),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isProcessingOrder = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to place order: $e',
                  style: AppStyles.bodyStyle),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.lightGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout', style: AppStyles.subHeadingStyle),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Order Summary'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                              'Items', '${widget.itemCount}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Subtotal',
                              '\$${widget.totalAmount.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Shipping', '\$10.00'),
                          const Divider(
                              color: AppColors.softGold, height: 20),
                          _buildSummaryRow(
                            'Total',
                            '\$${(widget.totalAmount + 10).toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Shipping Address'),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: _addressController,
                        label: 'Street Address',
                        icon: Icons.location_on,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              icon: Icons.location_city),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                              controller: _zipController,
                              label: 'ZIP Code',
                              icon: Icons.pin,
                              keyboardType: TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Payment Method'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPaymentOption('Card', Icons.credit_card),
                        const SizedBox(width: 12),
                        _buildPaymentOption('Cash', Icons.money),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedPaymentMethod == 'Card') ...[
                      _buildTextField(
                          controller: _cardNumberController,
                          label: 'Card Number',
                          icon: Icons.credit_card),
                      const SizedBox(height: 12),
                      _buildTextField(
                          controller: _cardHolderController,
                          label: 'Card Holder Name',
                          icon: Icons.person_outline),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.richGold,
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the terms and conditions',
                            style: AppStyles.bodyStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessingOrder ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isProcessingOrder
                        ? AppColors.softGold.withOpacity(0.5)
                        : AppColors.richGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Place Order - \$${(widget.totalAmount + 10).toStringAsFixed(2)}',
                    style: AppStyles.buttonTextStyle.copyWith(
                        color: AppColors.deepBlack),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppStyles.subHeadingStyle);
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppStyles.subHeadingStyle
              : AppStyles.bodyStyle,
        ),
        Text(
          value,
          style: isTotal
              ? AppStyles.cardValueStyle
              : AppStyles.bodyStyle,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: AppStyles.bodyStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppStyles.smallTextStyle,
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        filled: true,
        fillColor: AppColors.cardBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.richGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    final isSelected = selectedPaymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.richGold.withOpacity(0.2)
                : AppColors.cardBlack,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.richGold
                  : AppColors.richGold.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.richGold : AppColors.softGold,
                  size: 32),
              const SizedBox(height: 8),
              Text(
                method,
                style: AppStyles.bodyStyle.copyWith(
                  color: isSelected ? AppColors.richGold : AppColors.softGold,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}