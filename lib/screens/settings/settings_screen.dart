import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: const Center(
        child: Text(
          'Fitur Pengaturan\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.grey),
        ),
      ),
    );
  }
}
