import 'package:flutter/material.dart';
import 'package:splash_screen/data/repositories/supabase_repository.dart';
import 'package:splash_screen/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../restaurant/restaurant_dashboard_screen.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import '../../../core/widgets/sheets/app_bottom_sheets.dart';

class CustomerAuthSheet extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const CustomerAuthSheet({super.key, required this.onAuthSuccess});

  @override
  State<CustomerAuthSheet> createState() => _CustomerAuthSheetState();
}

class _CustomerAuthSheetState extends State<CustomerAuthSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between Login and Sign Up

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await SupabaseService().signIn(email, password);

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final role = await SupabaseRepository().getUserRole(user.id);
          if (role == 'admin') {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                (route) => false,
              );
            }
            return;
          } else if (role == 'restaurant') {
            final isOnboarded = await SupabaseRepository().checkIsOnboarded(
              user.id,
            );
            if (!isOnboarded) {
              if (mounted) {
                Navigator.of(context).pop();
                AppBottomSheets.showOnboardingSheet(context);
              }
            } else {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const RestaurantDashboardScreen(),
                  ),
                  (route) => false,
                );
              }
            }
            return;
          }
        }
      } else {
        await SupabaseRepository().signUpCustomer(email, password);
      }

      if (mounted) {
        widget.onAuthSuccess();
        Navigator.of(context).pop(); // Close sheet on success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorOccurred(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await SupabaseRepository().signInWithGoogle();
      // Google Auth redirects in browser. When returning, supabase handles the session.
      // After redirect back to the app, the session should be restored.
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.googleSignInFailed(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.95, // Opens almost to the top
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLogin
                            ? AppLocalizations.of(context)!.loginTitle
                            : AppLocalizations.of(context)!.registerTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? AppLocalizations.of(context)!.loginSubtitle
                            : AppLocalizations.of(context)!.registerSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        hintText: AppLocalizations.of(context)!.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        hintText: AppLocalizations.of(context)!.password,
                        isPassword: true,
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      CustomButton(
                        text: _isLogin
                            ? AppLocalizations.of(context)!.signIn
                            : AppLocalizations.of(context)!.registerButton,
                        onPressed: _handleAuth,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppLocalizations.of(context)!.or,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Google Auth Button
                      CustomButton(
                        text: AppLocalizations.of(context)!.continueWithGoogle,
                        onPressed: _handleGoogleSignIn,
                        isOutlined: true,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                          width: 24,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppLocalizations.of(context)!.or,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Toggle Auth Mode
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? AppLocalizations.of(
                                    context,
                                  )!.dontHaveAccountSignUp
                                : AppLocalizations.of(
                                    context,
                                  )!.alreadyHaveAccountSignIn,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ], // Closes inner Column's children
                  ), // Closes inner Column
                ), // Closes SingleChildScrollView
              ), // Closes Expanded
            ], // Closes outer Column's children
          ), // Closes outer Column
        ), // Closes Padding
      ), // Closes SafeArea
    ); // Closes Container
  }
}
