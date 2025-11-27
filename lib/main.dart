import 'package:flutter/material.dart';
import 'package:harvestguard_bd/screens/auth_screen.dart';
import 'package:harvestguard_bd/screens/batch_screen.dart';
import 'package:harvestguard_bd/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HarvestGuard',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (c) => HomeScreen(),
        '/auth': (c) => AuthScreen(),
        '/batches': (c) => BatchScreen(),
      },
    );
  }
}
