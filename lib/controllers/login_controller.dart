import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/services/api_service.dart';
import 'package:water365/feature/home_screen.dart';

class LoginController extends GetxController {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final isLoading = false.obs;
  final apiService = ApiService();

  Future<void> login() async {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Attention",
        "Please enter username and password",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final body =
          '<UserLogin xmlns="http://tempuri.org/"><userName>$username</userName><UserPwd>$password</UserPwd></UserLogin>';
      final responseBody = await apiService.soapRequest(
        operation: "UserLogin",
        body: body,
      );

      if (responseBody != null) {
        final result = apiService.parseSoapResponse(responseBody, "UserLogin");
        if (result == "success") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('password', password);

          Get.offAll(() => const HomeScreen());
        } else {
          Get.snackbar(
            "Attention",
            result,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
