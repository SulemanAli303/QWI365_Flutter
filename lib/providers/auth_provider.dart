import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/network_api_service.dart';
import '../utils/api_urls.dart';

class AuthProvider with ChangeNotifier {
  final NetworkApiService _apiService = NetworkApiService();
  bool _loading = false;
  bool get loading => _loading;

  String? _username;
  String? get username => _username;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    setLoading(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.loginUrl,
        soapAction: ApiUrls.loginAction,
        params: {
          '_methodName': ApiUrls.loginMethod,
          'userName': username,
          'UserPwd': password,
        },
      );

      final result = NetworkApiService.parseSoapResponse(
        response,
        'UserLoginResult',
      );
      print('result---${result.toString()}');
      if (result == 'success') {
        _isLoggedIn = true;
        _username = username;

        final pref = await SharedPreferences.getInstance();
        await pref.setString('username', username);
        await pref.setString('password', password);
        await pref.setBool('isLoggedIn', true);
        notifyListeners();
      } else {
        throw 'Invalid Credentials';
      }
    } catch (e) {
      print('e---------- ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<String> forgotPassword(String username) async {
    setLoading(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.forgotUrl,
        soapAction: ApiUrls.forgotAction,
        params: {'_methodName': ApiUrls.forgotMethod, 'userName': username},
      );

      final result = NetworkApiService.parseSoapResponse(
        response,
        'ForgotPasswordResult',
      );
      return result.toString();
    } catch (e) {
      print('forgotPassword error: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _username = null;
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('isLoggedIn', false);
    // Note: We don't remove username/password if rememberMe was true, just the loggedIn status
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final pref = await SharedPreferences.getInstance();
    _isLoggedIn = pref.getBool('isLoggedIn') ?? false;
    _username = pref.getString('username');
    notifyListeners();
  }
}
