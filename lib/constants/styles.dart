import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  // ================= HEADINGS =================
  static const headingStyle = TextStyle(
    fontFamily: 'Poppins',      // Modern, bold for headings
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.richGold,
  );

  static const subHeadingStyle = TextStyle(
    fontFamily: 'Poppins',      // Slightly smaller heading
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.lightGold,
  );

  // ================= BODY TEXT =================
  static const bodyStyle = TextStyle(
    fontFamily: 'Roboto',       // Main body text
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.softGold,
  );

  static const smallTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.softGold,
  );

  // ================= CARD STYLES =================
  static const cardTitleStyle = TextStyle(
    fontFamily: 'Montserrat',   // Card headings
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.lightGold,
  );

  static const cardValueStyle = TextStyle(
    fontFamily: 'Lato',         // Card numbers, prices
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.richGold,
  );

  static const buttonTextStyle = TextStyle(
    fontFamily: 'Lato',         // Buttons
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.deepBlack,
  );

  static const outlinedButtonTextStyle = TextStyle(
    fontFamily: 'Lato',         // Outlined buttons
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.richGold,
  );
}
