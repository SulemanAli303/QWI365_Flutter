import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water365/controllers/forgot_controller.dart';
import 'package:water365/utils/app_colors.dart';
import 'package:water365/widgets/app_logo.dart';
import 'package:water365/widgets/custom_textfield.dart';
import 'package:water365/widgets/custom_button.dart';
import 'package:water365/widgets/full_loader.dart';

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(
        () => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
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
                  const SizedBox(height: 30),
                  CustomButton(
                    text: "SUBMIT",
                    onPressed: () => controller.submit(),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Get.toNamed('/login'),
                    child: const Text(
                      "Never mind, let's try again",
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
            if (controller.isLoading.value) const CustomFullLoader(),
          ],
        ),
      ),
    );
  }
}
