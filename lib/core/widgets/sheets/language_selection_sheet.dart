import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import 'package:splash_screen/logic/locale_bloc/locale_cubit.dart';

class LanguageSelectionSheet extends StatelessWidget {
  const LanguageSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              AppLocalizations.of(context)!.language,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Image.asset('assets/images/flag_ps.png', width: 24, height: 24),
            title: Text(AppLocalizations.of(context)!.arabic),
            onTap: () {
              context.read<LocaleCubit>().changeLanguage('ar');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Image.asset('assets/images/flag_us.png', width: 24, height: 24),
            title: Text(AppLocalizations.of(context)!.english),
            onTap: () {
              context.read<LocaleCubit>().changeLanguage('en');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
