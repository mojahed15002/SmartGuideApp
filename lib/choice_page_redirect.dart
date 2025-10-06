import 'package:flutter/material.dart';
import 'main.dart'; // لأن ChoicePage موجودة في main

class ChoicePageRedirect extends StatelessWidget {
  final dynamic themeNotifier;
  const ChoicePageRedirect({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ChoicePage(themeNotifier: themeNotifier);
  }
}
