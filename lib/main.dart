import 'package:flutter/material.dart';
import 'package:smart_health_card/database/local_storage.dart';
import 'package:smart_health_card/services/qr_service.dart';
import 'test_screen_b.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialise Hive pour le cache
  await LocalStorage.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Health Card - Tests B',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,  // Important pour le QR scanner
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const TestScreenB(),
    );
  }
}