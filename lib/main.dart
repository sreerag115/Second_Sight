import 'package:flutter/material.dart';
import 'login_page.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Second Sight',
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
