import 'package:flutter/material.dart';
import 'package:water365/utils/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        cursorColor: AppColors.primaryOrange,
        style: TextStyle(color: AppColors.textColor, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Image.asset(
            prefixIcon,
            scale: 3,
            color: AppColors.textColor,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textColor.withOpacity(0.5),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
