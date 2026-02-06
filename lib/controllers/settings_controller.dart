import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/models/site.dart';

class SettingsController extends GetxController {
  final mapMode = "Satellite".obs;
  final defSite = "none".obs;
  final sites = <Site>[].obs;
  final username = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    username.value = prefs.getString('username') ?? "User";

    final mode = prefs.getString('mapMode') ?? "sat";
    mapMode.value = (mode == "sat") ? "Satellite" : "Normal";

    defSite.value = prefs.getString('defSite') ?? "none";

    // Load available sites from arguments or shared prefs if cached
    if (Get.arguments != null && Get.arguments['sites'] != null) {
      sites.value = Get.arguments['sites'];
    } else {
      // Logic from Swift: siteNames = sites.map { $0.siteName }
      // This is usually populated after Sites are fetched in Home or Sites screen.
    }
  }

  void updateMapMode(String mode) async {
    mapMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mapMode', mode == "Satellite" ? "sat" : "street");
  }

  void updateDefaultSite(String site) async {
    defSite.value = site;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defSite', site);
  }
}
