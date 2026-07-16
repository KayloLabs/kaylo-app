import 'package:flutter/material.dart';
import '../../../../core/widgets/language_selector_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const LanguageSelectorSheet(),
            );
          },
          child: const Text('Language Settings'),
        ),
      ),
    );
  }
}
