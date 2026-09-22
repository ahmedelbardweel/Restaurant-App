import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/supabase_repository.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/auth_bloc/auth_event.dart';
import 'logic/locale_bloc/locale_cubit.dart';
import 'screens/splash_loader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // For Android
      statusBarBrightness: Brightness.dark, // For iOS
    ),
  );

  await Supabase.initialize(
    url: 'https://srawlltewvegexdjbsxy.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyYXdsbHRld3ZlZ2V4ZGpic3h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzE1NjAsImV4cCI6MjEwNTU0NzU2MH0.8puCn7lM2-yFBJ8J2w-QaeO5RQhLugADbr0TAVlDf0o',
  );

  final supabaseRepository = SupabaseRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(repository: supabaseRepository)
                ..add(AuthCheckRequested()),
        ),
        BlocProvider<LocaleCubit>(create: (context) => LocaleCubit()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          title: 'Restaurant App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashLoaderScreen(),
          builder: (context, child) {
            // Global scale down (Zoom out) by reducing the text scale factor.
            // This is the safest way to "shrink" the UI without breaking constraints.
            final mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: const TextScaler.linear(0.85),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
