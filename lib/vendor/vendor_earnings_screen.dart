import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';

class VendorEarningsScreen extends StatefulWidget {
  @override
  _VendorEarningsScreenState createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends State<VendorEarningsScreen> {
  double totalEarnings = 0.0;
  double availableBalance = 0.0;
  double withdrawnAmount = 0.0;
  int completedOrders = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final vendorId = FirebaseAuth.instance.currentUser?.uid;
      if (vendorId == null) return;

      // Get completed orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .where('orderStatus', isEqualTo: 'Complete')
          .get();

      double total = 0.0;
      int orderCount = 0;

      for (var doc in ordersSnapshot.docs) {
        orderCount++;
        final data = doc.data();
        final totalAmount = data['totalAmount'];
        if (totalAmount != null) {
          if (totalAmount is num) {
            total += totalAmount.toDouble();
          } else if (totalAmount is String) {
            total += double.tryParse(totalAmount) ?? 0.0;
          }
        }
      }

      // Get withdrawn amount
      final withdrawalsSnapshot = await FirebaseFirestore.instance
          .collection('withdrawals')
          .where('vendorId', isEqualTo: vendorId)
          .where('status', isEqualTo: 'completed')
          .get();

      double withdrawn = 0.0;
      for (var doc in withdrawalsSnapshot.docs) {
        final amount = doc['amount'];
        if (amount != null) {
          withdrawn += (amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0);
        }
      }

      setState(() {
        completedOrders = orderCount;
        totalEarnings = total;
        withdrawnAmount = withdrawn;
        availableBalance = total - withdrawn;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading earnings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showWithdrawalDialog() {
    final amountController = TextEditingController();
    String selectedMethod = 'JazzCash';
    final accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.richGold),
              SizedBox(width: 12),
              Text(
                'Withdraw Money',
                style: TextStyle(color: AppColors.lightGold, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: AppColors.softGold.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$${availableBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.richGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.lightGold),
                  decoration: InputDecoration(
                    labelText: 'Withdrawal Amount (\$)',
                    labelStyle: TextStyle(color: AppColors.richGold.withOpacity(0.7)),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(color: AppColors.richGold),
                    filled: true,
                    fillColor: AppColors.deepBlack.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    color: AppColors.richGold.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMethod,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBlack,
                      style: TextStyle(color: AppColors.lightGold),
                      icon: Icon(Icons.arrow_drop_down, color: AppColors.richGold),
                      items: [
                        'JazzCash',
                        'EasyPaisa',
                        'Bank Account',
                        'Bank Transfer',
                      ].map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Row(
                            children: [
                              Icon(
                                method.contains('Jazz') ? Icons.phone_android :
                                method.contains('Easy') ? Icons.phone_iphone :
                                Icons.account_balance,
                                color: AppColors.richGold,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(method),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMethod = value!;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: accountController,
                  keyboardType: selectedMethod.contains('Bank') 
                      ? TextInputType.text 
                      : TextInputType.phone,
                  style: TextStyle(color: AppColors.lightGold),
                  decoration: InputDecoration(
                    labelText: selectedMethod.contains('Bank') 
                        ? 'Account Number' 
                        : 'Phone Number',
                    labelStyle: TextStyle(color: AppColors.richGold.withOpacity(0.7)),
                    prefixIcon: Icon(
                      selectedMethod.contains('Bank') 
                          ? Icons.account_balance 
                          : Icons.phone,
                      color: AppColors.richGold,
                    ),
                    filled: true,
                    fillColor: AppColors.deepBlack.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightGold, AppColors.richGold],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter valid amount')),
                    );
                    return;
                  }
                  if (amount > availableBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Insufficient balance')),
                    );
                    return;
                  }
                  if (accountController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter account details')),
                    );
                    return;
                  }

                  await _submitWithdrawal(
                    amount,
                    selectedMethod,
                    accountController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.deepBlack,
                  shadowColor: Colors.transparent,
                ),
                child: Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitWithdrawal(double amount, String method, String account) async {
    try {
      final vendorId = FirebaseAuth.instance.currentUser?.uid;
      if (vendorId == null) return;

      await FirebaseFirestore.instance.collection('withdrawals').add({
        'vendorId': vendorId,
        'amount': amount,
        'paymentMethod': method,
        'accountDetails': account,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'type': 'vendor',
        'vendorMessageRead': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadEarnings();
    } catch (e) {
      print('❌ Error submitting withdrawal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text('My Earnings', style: TextStyle(color: AppColors.lightGold)),
        iconTheme: IconThemeData(color: AppColors.richGold),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEarnings,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildEarningsCard(
                    'Completed Orders',
                    completedOrders.toString(),
                    Icons.check_circle,
                    Colors.green,
                    isCount: true,
                  ),
                  SizedBox(height: 16),
                  _buildEarningsCard(
                    'Total Earnings',
                    totalEarnings,
                    Icons.trending_up,
                    Colors.green,
                  ),
                  SizedBox(height: 16),
                  _buildEarningsCard(
                    'Available Balance',
                    availableBalance,
                    Icons.account_balance_wallet,
                    AppColors.richGold,
                  ),
                  SizedBox(height: 16),
                  _buildEarningsCard(
                    'Withdrawn Amount',
                    withdrawnAmount,
                    Icons.payment,
                    Colors.orange,
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.richGold),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Earnings are calculated from completed orders',
                            style: TextStyle(
                              color: AppColors.lightGold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold, AppColors.richGold],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.4),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: availableBalance > 0 ? _showWithdrawalDialog : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.deepBlack,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Withdraw Money',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildWithdrawalHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsCard(String title, dynamic value, IconData icon, Color color, {bool isCount = false}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.softGold.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isCount ? value : '\$${(value as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalHistory() {
    final vendorId = FirebaseAuth.instance.currentUser?.uid;
    if (vendorId == null) return SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('withdrawals')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            color: AppColors.cardBlack,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No withdrawal history',
                  style: TextStyle(color: AppColors.softGold),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdrawal History',
              style: TextStyle(
                color: AppColors.lightGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = data['amount'];
              final amountStr = amount is num 
                  ? amount.toStringAsFixed(2) 
                  : amount.toString();
              
              return Card(
                color: AppColors.cardBlack,
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    data['status'] == 'completed'
                        ? Icons.check_circle
                        : data['status'] == 'rejected'
                        ? Icons.cancel
                        : Icons.pending,
                    color: data['status'] == 'completed'
                        ? Colors.green
                        : data['status'] == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text(
                    '\$$amountStr',
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${data['paymentMethod']} - ${data['accountDetails']}',
                    style: TextStyle(color: AppColors.softGold),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: data['status'] == 'completed'
                          ? Colors.green.withOpacity(0.2)
                          : data['status'] == 'rejected'
                          ? Colors.red.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: data['status'] == 'completed'
                            ? Colors.green
                            : data['status'] == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
