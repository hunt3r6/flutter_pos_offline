import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/screens/main_screen.dart';
import 'package:flutter_pos_offline/services/pos_provider.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PosProvider(),
      child: MaterialApp(
        title: 'POS Offline App',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}
