import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';

class AdminWithdrawalManagementScreen extends StatefulWidget {
  @override
  _AdminWithdrawalManagementScreenState createState() =>
      _AdminWithdrawalManagementScreenState();
}

class _AdminWithdrawalManagementScreenState
    extends State<AdminWithdrawalManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          selectedFilter = 'all';
        });
      }
    });
    print('🎯 Admin Withdrawal Management Screen Initialized');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveWithdrawal(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('withdrawals')
          .doc(docId)
          .update({
        'status': 'completed',
        'approvedDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectWithdrawal(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('withdrawals')
          .doc(docId)
          .update({
        'status': 'rejected',
        'rejectedDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showWithdrawalDetails(Map<String, dynamic> data, String docId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.richGold),
            SizedBox(width: 12),
            Text(
              'Withdrawal Details',
              style: TextStyle(color: AppColors.lightGold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', userName),
            _buildDetailRow('Amount', '\$${(data['amount'] ?? 0.0).toStringAsFixed(2)}'),
            _buildDetailRow('Payment Method', data['paymentMethod'] ?? 'N/A'),
            _buildDetailRow('Account Details', data['accountDetails'] ?? 'N/A'),
            _buildDetailRow('Status', (data['status'] ?? 'pending').toString().toUpperCase()),
            _buildDetailRow('Type', data['type'] ?? 'N/A'),
            if (data['vendorId'] != null)
              _buildDetailRow('Vendor ID', data['vendorId']),
            if (data['riderId'] != null)
              _buildDetailRow('Rider ID', data['riderId']),
          ],
        ),
        actions: [
          if ((data['status'] ?? 'pending') == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectWithdrawal(docId);
              },
              child: Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightGold, AppColors.richGold],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _approveWithdrawal(docId, data);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.deepBlack,
                  shadowColor: Colors.transparent,
                ),
                child: Text('Approve'),
              ),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: AppColors.richGold)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.softGold.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.lightGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text(
          'Withdrawal Management',
          style: TextStyle(color: AppColors.lightGold),
        ),
        iconTheme: IconThemeData(color: AppColors.richGold),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.softGold,
          tabs: [
            Tab(text: 'Vendor Withdrawals'),
            Tab(text: 'Rider Withdrawals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWithdrawalList('vendor'),
          _buildWithdrawalList('rider'),
        ],
      ),
    );
  }

  Widget _buildWithdrawalList(String type) {
    return Column(
      children: [
        // Filter Buttons
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              SizedBox(width: 8),
              _buildFilterChip('Completed', 'completed'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getWithdrawalStream(type),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.richGold),
                );
              }

              // Get docs
              var allDocs = snapshot.data!.docs;
              
              // Client-side filter
              if (selectedFilter != 'all') {
                allDocs = allDocs.where((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return data['status'] == selectedFilter;
                }).toList();
              }

              // Client-side sort by requestDate descending
              allDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = (aData['requestDate'] as Timestamp?)?.toDate() ?? DateTime(0);
                final bTime = (bData['requestDate'] as Timestamp?)?.toDate() ?? DateTime(0);
                return bTime.compareTo(aTime);
              });

              if (allDocs.isEmpty) {
                return Center(
                  child: Text(
                    selectedFilter == 'all'
                        ? 'No withdrawal requests'
                        : 'No $selectedFilter withdrawal requests',
                    style: TextStyle(color: AppColors.softGold),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: allDocs.length,
                itemBuilder: (context, index) {
                  final doc = allDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;
                  
                  // Get user ID based on type
                  String userId = type == 'vendor' 
                      ? (data['vendorId'] ?? '') 
                      : (data['riderId'] ?? '');

                  return _buildWithdrawalCardWithName(docId, data, userId, type);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.richGold : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.richGold : AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.deepBlack : AppColors.lightGold,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getWithdrawalStream(String type) {
    return FirebaseFirestore.instance
        .collection('withdrawals')
        .where('type', isEqualTo: type)
        .snapshots();
  }

  // Widget with FutureBuilder to fetch name
  Widget _buildWithdrawalCardWithName(String docId, Map<String, dynamic> data, String userId, String type) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String userName = 'Loading...';
        
        if (userSnapshot.connectionState == ConnectionState.done) {
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            userName = userData?['name'] ?? 'Unknown User';
          } else {
            userName = 'Unknown User';
          }
        }
        
        return _buildWithdrawalCard(docId, data, userName);
      },
    );
  }

  Widget _buildWithdrawalCard(String docId, Map<String, dynamic> data, String userName) {
    final status = (data['status'] ?? 'pending') as String;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    final amount = data['amount'] ?? 0.0;
    final amountStr = (amount is num ? amount : double.tryParse(amount.toString()) ?? 0.0)
        .toStringAsFixed(2);

    return Card(
      color: AppColors.cardBlack,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.richGold.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _showWithdrawalDetails(data, docId, userName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name - Bold and prominent
                        Text(
                          userName,
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Amount
                        Text(
                          '\$$amountStr',
                          style: TextStyle(
                            color: AppColors.lightGold,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          data['paymentMethod'] ?? 'N/A',
                          style: TextStyle(
                            color: AppColors.softGold.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(color: AppColors.richGold.withOpacity(0.2)),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    (data['paymentMethod'] ?? '').contains('Bank')
                        ? Icons.account_balance
                        : Icons.phone,
                    color: AppColors.richGold,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    data['accountDetails'] ?? 'N/A',
                    style: TextStyle(
                      color: AppColors.softGold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (status == 'pending') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectWithdrawal(docId),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.lightGold, AppColors.richGold],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _approveWithdrawal(docId, data),
                          icon: Icon(Icons.check, size: 18),
                          label: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.deepBlack,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}