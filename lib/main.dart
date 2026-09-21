import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/supabase_repository.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/auth_bloc/auth_event.dart';
import 'screens/splash_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://srawlltewvegexdjbsxy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyYXdsbHRld3ZlZ2V4ZGpic3h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzE1NjAsImV4cCI6MjEwNTU0NzU2MH0.8puCn7lM2-yFBJ8J2w-QaeO5RQhLugADbr0TAVlDf0o',
  );

  final supabaseRepository = SupabaseRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(repository: supabaseRepository)..add(AuthCheckRequested()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashLoaderScreen(),
    );
  }
}
