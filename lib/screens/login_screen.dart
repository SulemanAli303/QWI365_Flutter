import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qwi365/utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }

  void _loadStoredCredentials() async {
    final pref = await SharedPreferences.getInstance();
    // Always pre-fill if data exists
    setState(() {
      _userController.text = pref.getString('username') ?? '';
      _passController.text = pref.getString('password') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/e365w.png', height: 70),
                    const SizedBox(width: 15),
                    Text(
                      'QWI365',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _userController,
                  cursorColor: AppColors.orangeColor,
                  style: const TextStyle(color: AppColors.whiteColor),
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 14,
                    ),
                    fillColor: AppColors.whiteColor.withOpacity(.2),
                    filled: true,
                    prefixIcon: const Icon(
                      Icons.person,
                      color: AppColors.whiteColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: AppColors.orangeColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.whiteColor),
                  cursorColor: AppColors.orangeColor,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 14,
                    ),
                    fillColor: AppColors.whiteColor.withOpacity(.2),
                    filled: true,
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppColors.whiteColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: AppColors.orangeColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: authProvider.loading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                await authProvider.login(
                                  _userController.text,
                                  _passController.text,
                                );
                                if (mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.home,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeColor,
                      foregroundColor: AppColors.orangeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: authProvider.loading
                        ? const CircularProgressIndicator(
                            color: AppColors.whiteColor,
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(color: AppColors.whiteColor),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgot),
                  child: const Text(
                    'Forgot your password?',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
