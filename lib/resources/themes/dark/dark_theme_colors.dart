import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/themes/color_styles.dart';

class DarkThemeColors extends ColorStyles {
  @override
  GeneralColors get general => const GeneralColors(
        background: Color(0xFF1F1929),
        content: Colors.white,
        primaryAccent: Color(0xFFFF8383),
        surface: Color(0xFF1F1929),
        surfaceContent: Colors.white,
      );

  @override
  AppBarColors get appBar => const AppBarColors(
        background: Color(0xFF1F1929),
        content: Colors.white,
      );

  @override
  BottomTabBarColors get bottomTabBar => const BottomTabBarColors(
        background: Colors.white,
        iconSelected: Color(0xFF1455D4),
        iconUnselected: Color(0xFF9EADBD),
        labelSelected: Color(0xFF1455D4),
        labelUnselected: Color(0xFF9EADBD),
      );
}
