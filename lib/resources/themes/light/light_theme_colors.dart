import 'package:flutter/material.dart';
import '/resources/themes/color_styles.dart';
import 'package:nylo_framework/nylo_framework.dart';

class LightThemeColors extends ColorStyles {
  @override
  GeneralColors get general => const GeneralColors(
        background: Colors.white,
        content: Color(0xFF241E30),
        primaryAccent: Color(0xFFd21e1d),
        surface: Colors.white,
        surfaceContent: Color(0xFF241E30),
      );

  @override
  AppBarColors get appBar => const AppBarColors(
        background: Colors.white,
        content: Color(0xFF241E30),
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
