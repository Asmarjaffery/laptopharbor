import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class ViewCategoriesScreen extends StatefulWidget {
  const ViewCategoriesScreen({super.key});

  @override
  State<ViewCategoriesScreen> createState() => _ViewCategoriesScreenState();
}

class _ViewCategoriesScreenState extends State<ViewCategoriesScreen> {
  final CollectionReference categoriesRef =
      FirebaseFirestore.instance.collection('categories');

  Future<void> deleteCategory(String docId) async {
    // Confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Delete Category', style: TextStyle(color: AppColors.lightGold)),
        content: Text(
          'Are you sure you want to delete this category?',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await categoriesRef.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Category deleted successfully"),
            backgroundColor: AppColors.richGold,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete category"),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  Future<void> editCategory(
    String docId,
    String currentName,
    String currentDesc,
    bool currentStatus,
  ) async {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController descController =
        TextEditingController(text: currentDesc);
    bool isActive = currentStatus;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBlack,
          title: Text('Edit Category', style: TextStyle(color: AppColors.lightGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppColors.lightGold),
                  decoration: InputDecoration(
                    labelText: "Category Name",
                    labelStyle: TextStyle(color: AppColors.richGold),
                    filled: true,
                    fillColor: AppColors.deepBlack.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: TextStyle(color: AppColors.lightGold),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: AppColors.richGold),
                    filled: true,
                    fillColor: AppColors.deepBlack.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SwitchListTile(
                  title: Text('Active Status', style: TextStyle(color: AppColors.lightGold)),
                  value: isActive,
                  onChanged: (val) {
                    setDialogState(() {
                      isActive = val;
                    });
                  },
                  activeColor: AppColors.richGold,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.richGold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
              onPressed: () async {
                try {
                  await categoriesRef.doc(docId).update({
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'isActive': isActive,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Category updated successfully"),
                      backgroundColor: AppColors.richGold,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to update category"),
                      backgroundColor: Colors.red[900],
                    ),
                  );
                }
              },
              child: Text('Save', style: TextStyle(color: AppColors.deepBlack)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Category Management', style: TextStyle(color: AppColors.lightGold)),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add New Category Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addCategory);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.deepBlack, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add New Category',
                      style: TextStyle(
                        color: AppColors.deepBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: categoriesRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                }

                final categories = snapshot.data!.docs;

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 80,
                          color: AppColors.richGold.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No categories added yet",
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryData = category.data() as Map<String, dynamic>;
                    final isActive = categoryData['isActive'] ?? true;
                    final description = categoryData['description'] ?? '';

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Category Icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.deepBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.category,
                              color: AppColors.richGold,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),

                          // Category Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryData['name'] ?? 'Unnamed',
                                  style: TextStyle(
                                    color: AppColors.lightGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (description.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: AppColors.softGold.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      isActive ? Icons.check_circle : Icons.cancel,
                                      color: isActive
                                          ? AppColors.richGold
                                          : Colors.redAccent,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: AppColors.softGold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // More Options Menu
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: AppColors.lightGold,
                            ),
                            color: AppColors.cardBlack,
                            onSelected: (value) {
                              if (value == 'edit') {
                                editCategory(
                                  category.id,
                                  categoryData['name'] ?? '',
                                  categoryData['description'] ?? '',
                                  isActive,
                                );
                              } else if (value == 'delete') {
                                deleteCategory(category.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: AppColors.lightGold, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Edit',
                                      style: TextStyle(color: AppColors.lightGold),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}