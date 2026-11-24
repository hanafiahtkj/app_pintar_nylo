import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '/config/app.dart';
import '/resources/widgets/splash_screen.dart';
import '../resources/widgets/main_widget.dart';
import '/bootstrap/providers.dart';
import 'package:nylo_framework/nylo_framework.dart';

class Boot {
  static BootConfig nylo() => BootConfig(
        setup: () async {
          if (AppConfig.showSplashScreen) {
            runApp(SplashScreen.app());
          }

          await _init();
          return await setupApplication(providers);
        },
        boot: (Nylo nylo) async {
          await bootFinished(nylo, providers);

          runApp(Main(nylo));
        },
      );
}

Future<void> _init() async {
  MediaKit.ensureInitialized();
}
