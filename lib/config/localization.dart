import 'package:nylo_framework/nylo_framework.dart';

final class LocalizationConfig {
  static final String languageCode =
      getEnv('DEFAULT_LOCALE', defaultValue: 'id');

  static final LocaleType localeType = LocaleType.asDefined;

  static const String assetsDirectory = 'lang/';

  static const List<Locale> supportedLocales = <Locale>[
    Locale('id'),
    Locale('en'),
  ];

  static const String fallbackLanguageCode = 'id';

  static const List<String> rtlLanguages = <String>['ar', 'he', 'fa', 'ur'];

  static bool isRtl(String languageCode) => rtlLanguages.contains(languageCode);

  static final bool debugMissingKeys =
      getEnv('DEBUG_TRANSLATIONS', defaultValue: false).toString() == 'true';
}
