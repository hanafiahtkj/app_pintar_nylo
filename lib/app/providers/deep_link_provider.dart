import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/services/auth_service.dart';
import '/app/services/chrome_safari_browser_service.dart';
import '/app/services/pending_app_service.dart';

class DeepLinkProvider implements NyProvider {
  final AppLinks _appLinks = AppLinks();
  final ChromeSafariBrowserLauncher _browser = ChromeSafariBrowserLauncher();
  StreamSubscription<Uri>? _linkSub;

  @override
  Future<Nylo?> setup(Nylo nylo) async {
    return nylo;
  }

  @override
  Future<void> boot(Nylo nylo) async {
    _appLinks.getInitialLink().then((Uri? initialUri) {
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialUri);
        });
      }
    }).catchError((_) {});

    _linkSub?.cancel();
    _linkSub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'banjarmasinpintar') return;

    if (uri.host == 'close') {
      _browser.closeBrowser();
    }

    if (uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token']?.trim() ?? '';
      if (token.isNotEmpty && !AuthService().isLoggedIn) {
        AuthService().loginWithToken(token).then((user) {
          if (user != null) {
            PendingAppService().showPendingAppDialogIfNeeded();
          }
        }).catchError((_) {});
      }
      _browser.closeBrowser();
    }
  }
}
