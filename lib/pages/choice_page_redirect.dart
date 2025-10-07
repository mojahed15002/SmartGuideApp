import 'package:flutter/material.dart';
import 'choice_page.dart';

class ChoicePageRedirect extends StatelessWidget {
  final dynamic themeNotifier;
  const ChoicePageRedirect({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ChoicePage(themeNotifier: themeNotifier);
  }
}
