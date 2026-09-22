import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../../logic/locale_bloc/locale_cubit.dart';
import '../../../core/widgets/sheets/app_bottom_sheets.dart';
import '../../../core/widgets/custom_button.dart';
import 'package:splash_screen/l10n/app_localizations.dart';

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
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: titleColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 30),

                        // Language Switcher
                        Container(
                          margin: const EdgeInsets.only(bottom: 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            leading: Image.asset(
                              context.read<LocaleCubit>().state.languageCode ==
                                      'ar'
                                  ? 'assets/images/flag_ps.png'
                                  : 'assets/images/flag_us.png',
                              width: 24,
                              height: 24,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!.language,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!.changeLanguageDesc,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            onTap: () {
                              AppBottomSheets.showLanguageSheet(context);
                            },
                          ),
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
                    text: AppLocalizations.of(context)!.logout,
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
                  AppLocalizations.of(context)!.notLoggedIn,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.signInToManageProfile,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: titleColor.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: AppLocalizations.of(context)!.signIn,
                  backgroundColor: buttonColor,
                  onPressed: () {
                    AppBottomSheets.showCustomerAuthSheet(
                      context,
                      onAuthSuccess: () {},
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
