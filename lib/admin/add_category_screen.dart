import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  bool isActive = true;
  bool isLoading = false;

  Future<void> addCategory() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Category name is required"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('categories').add({
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Category Added Successfully"),
          backgroundColor: AppColors.richGold,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add category"),
          backgroundColor: Colors.red[900],
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Add New Category'),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ===== Premium Header =====
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold, AppColors.richGold],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.category, 
                        size: 40, color: AppColors.deepBlack),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Add Category',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightGold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: AppColors.richGold.withOpacity(0.5),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CREATE CATEGORY',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.richGold.withOpacity(0.7),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                  // ===== End of Header =====

                  // Category Name Field
                  buildField(
                    controller: nameController,
                    label: "Category Name",
                    icon: Icons.label_outline,
                  ),
                  SizedBox(height: 16),

                  // Description Field
                  buildField(
                    controller: descController,
                    label: "Description (Optional)",
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),

                  // Active Status Toggle
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.deepBlack.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.richGold.withOpacity(0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      value: isActive,
                      activeColor: AppColors.richGold,
                      title: Text(
                        "Active Status",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        isActive ? "Category is active" : "Category is inactive",
                        style: TextStyle(
                          color: AppColors.richGold.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (val) => setState(() => isActive = val),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Add Category Button
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
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : addCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.deepBlack,
                            )
                          : Text(
                              "Add Category",
                              style: TextStyle(
                                color: AppColors.deepBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.richGold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.lightGold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.richGold.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppColors.richGold),
        filled: true,
        fillColor: AppColors.deepBlack.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }
}