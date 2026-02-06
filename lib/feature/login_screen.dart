import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water365/controllers/login_controller.dart';
import 'package:water365/utils/app_colors.dart';
import 'package:water365/widgets/app_logo.dart';
import 'package:water365/widgets/custom_textfield.dart';
import 'package:water365/widgets/custom_button.dart';
import 'package:water365/widgets/full_loader.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(
        () => Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    const AppLogo(),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: controller.userController,
                      hintText: "Username",
                      prefixIcon: 'assets/account.png',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: controller.passController,
                      hintText: "Password",
                      prefixIcon: 'assets/lock.png',
                      isPassword: true,
                    ),
                    const SizedBox(height: 30),
                    CustomButton(
                      text: "LOGIN",
                      onPressed: () => controller.login(),
                    ),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () => Get.toNamed('/forgot'),
                      child: const Text(
                        "Forgot your password?",
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading.value) const CustomFullLoader(),
          ],
        ),
      ),
    );
  }
}
