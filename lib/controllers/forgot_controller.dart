import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water365/services/api_service.dart';

class ForgotController extends GetxController {
  final userController = TextEditingController();
  final isLoading = false.obs;
  final apiService = ApiService();

  Future<void> submit() async {
    final username = userController.text.trim();

    if (username.isEmpty) {
      Get.snackbar(
        "Attention",
        "Please enter username",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final body =
          '<ForgotPassword xmlns="http://tempuri.org/"><userName>$username</userName></ForgotPassword>';
      final responseBody = await apiService.soapRequest(
        operation: "ForgotPassword",
        body: body,
      );

      if (responseBody != null) {
        final result = apiService.parseSoapResponse(
          responseBody,
          "ForgotPassword",
        );
        Get.dialog(
          AlertDialog(
            title: const Text("Attention"),
            content: Text(result),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Dismiss"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
