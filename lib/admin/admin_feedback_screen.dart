import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  String _selectedRole = 'all';

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return AppColors.lightGold;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return AppColors.richGold;
      case 'vendor':
        return AppColors.lightGold;
      case 'rider':
        return AppColors.shineGold;
      default:
        return AppColors.softGold;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return Icons.person;
      case 'vendor':
        return Icons.store;
      case 'rider':
        return Icons.delivery_dining;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFeedbackOptions(String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility, color: AppColors.richGold),
              title: Text(
                'View Details',
                style: TextStyle(color: AppColors.lightGold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showFeedbackDetails(id, data);
              },
            ),
            Divider(color: AppColors.richGold.withOpacity(0.2)),
            ListTile(
              leading: Icon(Icons.pending, color: Colors.orange),
              title: Text(
                'Mark as Pending',
                style: TextStyle(color: AppColors.lightGold),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(id, 'pending');
              },
            ),
            Divider(color: AppColors.richGold.withOpacity(0.2)),
            ListTile(
              leading: Icon(Icons.hourglass_empty, color: AppColors.lightGold),
              title: Text(
                'Mark as In Progress',
                style: TextStyle(color: AppColors.lightGold),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(id, 'in_progress');
              },
            ),
            Divider(color: AppColors.richGold.withOpacity(0.2)),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text(
                'Mark as Resolved',
                style: TextStyle(color: Colors.green),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(id, 'resolved');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(id)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${status.toUpperCase()}'),
          backgroundColor: _getStatusColor(status),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showFeedbackDetails(String id, Map<String, dynamic> data) {
    final TextEditingController replyController = TextEditingController(
      text: data['adminResponse'] ?? '',
    );

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
            Icon(Icons.feedback, color: AppColors.richGold),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Feedback Details',
                style: TextStyle(color: AppColors.lightGold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', data['name'] ?? 'Unknown'),
              _buildDetailRow('Email', data['email'] ?? 'N/A'),
              _buildDetailRow('Role', (data['role'] ?? 'customer').toUpperCase()),
              if ((data['orderId'] ?? '').isNotEmpty)
                _buildDetailRow('Order ID', data['orderId']),
              _buildDetailRow('Status', (data['status'] ?? 'pending').toUpperCase()),
              SizedBox(height: 16),
              Text(
                'Message:',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  data['message'] ?? 'No message',
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Admin Response:',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: replyController,
                maxLines: 4,
                style: TextStyle(color: AppColors.lightGold),
                decoration: InputDecoration(
                  hintText: 'Type your response here...',
                  hintStyle: TextStyle(
                    color: AppColors.softGold.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.deepBlack.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.richGold.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.richGold.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.richGold,
                      width: 2,
                    ),
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
                if (replyController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a response'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('feedback')
                    .doc(id)
                    .update({
                  'adminResponse': replyController.text.trim(),
                  'status': 'resolved',
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reply sent successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.deepBlack,
                shadowColor: Colors.transparent,
              ),
              child: Text('Send Reply'),
            ),
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
    Query<Map<String, dynamic>> feedbackQuery = FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('createdAt', descending: true);

    if (_selectedRole != 'all') {
      feedbackQuery = feedbackQuery.where('role', isEqualTo: _selectedRole);
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.richGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feedback Management',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
              ),
              child: Icon(Icons.filter_list, color: AppColors.richGold),
            ),
            color: AppColors.cardBlack,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inbox, size: 20, color: AppColors.richGold),
                    const SizedBox(width: 8),
                    Text('All Roles', style: TextStyle(color: AppColors.lightGold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'customer',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: AppColors.richGold),
                    const SizedBox(width: 8),
                    Text('Customer', style: TextStyle(color: AppColors.lightGold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'vendor',
                child: Row(
                  children: [
                    Icon(Icons.store, size: 20, color: AppColors.lightGold),
                    const SizedBox(width: 8),
                    Text('Vendor', style: TextStyle(color: AppColors.lightGold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rider',
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining, size: 20, color: AppColors.shineGold),
                    const SizedBox(width: 8),
                    Text('Rider', style: TextStyle(color: AppColors.lightGold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: feedbackQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: AppColors.softGold.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No feedback found',
                    style: TextStyle(
                      color: AppColors.softGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final feedbackDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final feedback = feedbackDocs[index];
              final id = feedback.id;
              final data = feedback.data() as Map<String, dynamic>? ?? {};

              final name = data['name'] ?? 'Unknown';
              final email = data['email'] ?? 'N/A';
              final role = data['role'] ?? 'customer';
              final status = data['status'] ?? 'pending';

              return _buildFeedbackCard(id, data, name, email, role, status);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(
    String id,
    Map<String, dynamic> data,
    String name,
    String email,
    String role,
    String status,
  ) {
    return Card(
      color: AppColors.cardBlack,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.richGold.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: _getRoleColor(role).withOpacity(0.2),
              child: Icon(
                _getRoleIcon(role),
                color: _getRoleColor(role),
                size: 28,
              ),
            ),
            SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email,
                          color: AppColors.softGold.withOpacity(0.7),
                          size: 14),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            color: AppColors.softGold.withOpacity(0.7),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu only
            IconButton(
              icon: Icon(Icons.more_vert, color: AppColors.richGold),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: () => _showFeedbackOptions(id, data),
            ),
          ],
        ),
      ),
    );
  }
}