import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  
  // ✅ FREE: Local storage settings
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalOffers = false;

  // ✅ FREE: Display settings
  bool _isDarkMode = true;
  String _selectedLanguage = 'English';

  // ✅ FREE: Privacy settings (local only)
  bool _savePassword = false;

  // ✅ FREE: App preferences
  bool _autoSaveCart = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ✅ FREE: SharedPreferences (100% free, local storage)
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _emailNotifications = prefs.getBool('emailNotifications') ?? true;
          _orderUpdates = prefs.getBool('orderUpdates') ?? true;
          _promotionalOffers = prefs.getBool('promotionalOffers') ?? false;
          _isDarkMode = prefs.getBool('isDarkMode') ?? true;
          _selectedLanguage = prefs.getString('language') ?? 'English';
          _savePassword = prefs.getBool('savePassword') ?? false;
          _autoSaveCart = prefs.getBool('autoSaveCart') ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ FREE: Save to local storage
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
      
      _showSnackBar('Setting saved', AppColors.richGold);
    } catch (e) {
      debugPrint('Error saving setting: $e');
      _showSnackBar('Failed to save', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ FREE: Clear local cache
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.richGold),
            const SizedBox(width: 12),
            Text('Clear Cache', style: TextStyle(color: AppColors.lightGold)),
          ],
        ),
        content: Text(
          'This will clear temporary files. Your settings will remain saved.',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Only clear cache, not settings
        await prefs.remove('cachedData');
        await prefs.remove('tempImages');
        
        _showSnackBar('Cache cleared successfully!', AppColors.richGold);
      } catch (e) {
        _showSnackBar('Error clearing cache', Colors.red);
      }
    }
  }

  // ✅ FREE: URL launcher (no Firebase needed)
  Future<void> _openUrl(String urlString, String errorMessage) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  // ✅ FREE: Firebase Auth signOut (free quota: unlimited)
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.richGold),
            const SizedBox(width: 12),
            Text('Logout', style: TextStyle(color: AppColors.lightGold)),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ✅ FREE: Firebase Auth signOut
        await FirebaseAuth.instance.signOut();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  // ✅ FREE: Firestore delete + Auth delete (within free quota)
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text('Delete Account', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  '⚠️ This action CANNOT be undone!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The following will be deleted:',
                style: TextStyle(
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildDeleteItem('Profile and personal data'),
              _buildDeleteItem('Order history'),
              _buildDeleteItem('All settings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // ✅ FREE: Firestore delete (within 20k writes/day quota)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          // ✅ FREE: Delete orders
          final ordersSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .get();
          
          for (var doc in ordersSnapshot.docs) {
            await doc.reference.delete();
          }

          // ✅ FREE: Delete auth account
          await user.delete();

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error: ${e.toString()}', Colors.red);
        }
      }
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: AppColors.softGold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.lightGold,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.softGold, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.richGold,
        activeTrackColor: AppColors.richGold.withOpacity(0.5),
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.richGold, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.softGold, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.softGold, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language;
    return InkWell(
      onTap: () {
        setState(() => _selectedLanguage = language);
        _saveSetting('language', language);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.richGold.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.richGold
                : AppColors.softGold.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              language,
              style: TextStyle(
                color: isSelected ? AppColors.richGold : AppColors.lightGold,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.richGold, size: 20),
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
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.richGold),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FREE PLAN INFO
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.richGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                          color: AppColors.richGold, 
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Using Free Firebase Plan',
                            style: TextStyle(
                              color: AppColors.lightGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // NOTIFICATIONS (Email only - FREE)
                  _buildSectionTitle('📧 Notifications (Email)'),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Receive updates via email',
                    _emailNotifications,
                    (value) {
                      setState(() => _emailNotifications = value);
                      _saveSetting('emailNotifications', value);
                    },
                  ),
                  _buildSwitchTile(
                    'Order Updates',
                    'Get notified about order status',
                    _orderUpdates,
                    (value) {
                      setState(() => _orderUpdates = value);
                      _saveSetting('orderUpdates', value);
                    },
                  ),
                  _buildSwitchTile(
                    'Promotional Offers',
                    'Receive offers and discounts',
                    _promotionalOffers,
                    (value) {
                      setState(() => _promotionalOffers = value);
                      _saveSetting('promotionalOffers', value);
                    },
                  ),

                  // DISPLAY
                  _buildSectionTitle('🎨 Display'),
                  _buildSwitchTile(
                    'Dark Mode',
                    'Use dark theme',
                    _isDarkMode,
                    (value) {
                      setState(() => _isDarkMode = value);
                      _saveSetting('isDarkMode', value);
                    },
                  ),
                  _buildMenuTile(
                    Icons.language,
                    'Language',
                    _selectedLanguage,
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.cardBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Select Language',
                            style: TextStyle(color: AppColors.lightGold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLanguageOption('English'),
                              _buildLanguageOption('اردو'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // PRIVACY (Local only - FREE)
                  _buildSectionTitle('🔒 Privacy & Security'),
                  _buildSwitchTile(
                    'Remember Password',
                    'Save login credentials locally',
                    _savePassword,
                    (value) {
                      setState(() => _savePassword = value);
                      _saveSetting('savePassword', value);
                    },
                  ),
                  _buildMenuTile(
                    Icons.privacy_tip,
                    'Privacy Policy',
                    'Read our privacy policy',
                    () => _openUrl(
                      'https://yourcompany.com/privacy',
                      'Could not open link',
                    ),
                  ),
                  _buildMenuTile(
                    Icons.description,
                    'Terms & Conditions',
                    'Read terms of service',
                    () => _openUrl(
                      'https://yourcompany.com/terms',
                      'Could not open link',
                    ),
                  ),

                  // APP PREFERENCES
                  _buildSectionTitle('⚙️ App Preferences'),
                  _buildSwitchTile(
                    'Auto-Save Cart',
                    'Automatically save items',
                    _autoSaveCart,
                    (value) {
                      setState(() => _autoSaveCart = value);
                      _saveSetting('autoSaveCart', value);
                    },
                  ),
                  _buildMenuTile(
                    Icons.delete_outline,
                    'Clear Cache',
                    'Free up storage space',
                    _clearCache,
                  ),
                  _buildMenuTile(
                    Icons.info_outline,
                    'App Version',
                    'Version 1.0.0 (Free Plan)',
                    () => _showSnackBar(
                      'Latest version installed',
                      AppColors.richGold,
                    ),
                  ),

                  // ACCOUNT
                  _buildSectionTitle('👤 Account'),
                  _buildMenuTile(
                    Icons.logout,
                    'Logout',
                    'Sign out from account',
                    _logout,
                    iconColor: AppColors.richGold,
                  ),
                  _buildMenuTile(
                    Icons.delete_forever,
                    'Delete Account',
                    'Permanently delete account',
                    _deleteAccount,
                    iconColor: Colors.red,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}