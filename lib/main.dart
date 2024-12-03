import 'package:dakmadad/core/theme/app_theme.dart';
import 'package:dakmadad/features/auth/presentation/screens/start_screen.dart';
import 'package:dakmadad/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/domain/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
   await Supabase.initialize(
    url: 'https://ofblrlmpvkydtrjcftyk.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mYmxybG1wdmt5ZHRyamNmdHlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMwNTY4OTQsImV4cCI6MjA0ODYzMjg5NH0.1mNXYIOA6W5Zkn2tCduUzSLYccvcRCLeDlNSqYI73ZQ', // Replace with your Supabase anon key
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const StartScreen(),
      ),
    );
  }
}
