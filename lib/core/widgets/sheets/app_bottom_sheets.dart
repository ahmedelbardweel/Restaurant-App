import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splash_screen/screens/auth/dialogs/customer_auth_sheet.dart';
import 'package:splash_screen/core/widgets/sheets/language_selection_sheet.dart';
import 'package:splash_screen/screens/restaurant/dialogs/color_picker_sheet.dart';
import 'package:splash_screen/screens/auth/dialogs/restaurant_onboarding_sheet.dart';
import 'package:splash_screen/screens/admin/dialogs/restaurant_options_sheet.dart' as admin_opts;
import 'package:splash_screen/screens/admin/dialogs/create_restaurant_dialog.dart' as admin_create;

class AppBottomSheets {
  static void showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return const LanguageSelectionSheet();
      },
    );
  }

  static void showCustomerAuthSheet(BuildContext context, {required VoidCallback onAuthSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerAuthSheet(onAuthSuccess: onAuthSuccess),
    );
  }

  static void showOnboardingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OnboardingSheet(),
    );
  }

  static Future<Color?> showColorPickerSheet({
    required BuildContext context,
    required Color initialColor,
    required String label,
  }) {
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (_) => ColorPickerSheet(
        initialColor: initialColor,
        label: label,
      ),
    );
  }

  static void showRestaurantOptionsSheet({
    required BuildContext context,
    required Map<String, dynamic> restaurant,
    required VoidCallback onDeleteSuccess,
  }) {
    admin_opts.showRestaurantOptionsSheet(
      context: context,
      restaurant: restaurant,
      onDeleteSuccess: onDeleteSuccess,
    );
  }

  static void showCreateRestaurantSheet({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) {
    admin_create.showCreateRestaurantDialog(
      context: context,
      onSuccess: onSuccess,
    );
  }

  static void showCustomBottomSheet({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.originalSurfer(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
