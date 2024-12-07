import 'package:dakmadad/l10n/generated/S.dart';
import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFB71C1C),
      ),
      body: Center(
        child: Text(
          S.of(context)!.placeholderScreenText(title),
        ),
      ),
    );
  }
}
