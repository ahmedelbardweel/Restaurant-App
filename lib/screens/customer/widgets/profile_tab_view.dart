import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../auth/dialogs/customer_auth_sheet.dart';
import '../../../core/widgets/custom_button.dart';

class ProfileTabView extends StatelessWidget {
  final Color titleColor;
  final Color buttonColor;

  const ProfileTabView({
    super.key,
    required this.titleColor,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = titleColor == Colors.white;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final metadata = state.user.userMetadata ?? {};
          final name =
              metadata['full_name'] ??
              metadata['name'] ??
              state.user.email?.split('@').first ??
              'Customer';

          return Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 140,
                      left: 10,
                      right: 10,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: double.infinity),
                        const SizedBox(height: 20),

                        // Name & Email
                        Text(
                          name,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: titleColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 120,
                    left: 10,
                    right: 10,
                  ),
                  child: CustomButton(
                    text: 'Sign Out',
                    backgroundColor: const Color.fromARGB(255, 59, 1, 1),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not Logged In',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in to manage your profile and orders.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: titleColor.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Sign In',
                  backgroundColor: buttonColor,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CustomerAuthSheet(onAuthSuccess: () {}),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
