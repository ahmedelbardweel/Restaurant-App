import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../auth/dialogs/customer_auth_sheet.dart';
import '../../../core/widgets/custom_button.dart';

class ProfileTabView extends StatelessWidget {
  final Color titleColor;

  const ProfileTabView({super.key, required this.titleColor});

  @override
  Widget build(BuildContext context) {
    final isDark = titleColor == Colors.white;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final metadata = state.user.userMetadata ?? {};
          final name = metadata['full_name'] ?? metadata['name'] ?? state.user.email?.split('@').first ?? 'Customer';
          final phone = metadata['phone'] ?? 'Add your phone number';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Profile Avatar with glow
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.purpleAccent, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Name & Email
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.user.email ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: titleColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // Info Cards
                _buildProfileCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  subtitle: phone,
                  color: titleColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildProfileCard(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Addresses',
                  subtitle: 'Manage your saved addresses',
                  color: titleColor,
                  isDark: isDark,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildProfileCard(
                  icon: Icons.history_outlined,
                  title: 'Order History',
                  subtitle: 'View your past orders',
                  color: titleColor,
                  isDark: isDark,
                  onTap: () {},
                ),
                const SizedBox(height: 40),

                // Sign out Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Not Logged In',
                style: GoogleFonts.originalSurfer(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in to manage your profile and orders.',
                style: TextStyle(color: titleColor.withValues(alpha: 0.7), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomButton(
                  text: 'Sign In',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CustomerAuthSheet(
                        onAuthSuccess: () {},
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    // Override colors for the card to ensure readability
    final cardBgColor = Colors.white;
    final contentColor = Colors.black87;
    final subtitleColor = Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: contentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: contentColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: contentColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: subtitleColor,
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
