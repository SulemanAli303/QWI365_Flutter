import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/feature/login_screen.dart';
import 'package:water365/feature/home_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('username');
    final String? pass = prefs.getString('password');

    if (user != null && pass != null) {
      Get.offAll(() => const HomeScreen());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }
}
