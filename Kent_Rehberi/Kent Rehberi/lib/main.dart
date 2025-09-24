import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ezlqjzozvoqsqoayohpe.supabase.co',
    anonKey: //Kullanılan keye bağlı olarak değişebilir.Spesifik olarak kullanıldığı için key koyulamamıştır.
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harita Uygulaması',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}