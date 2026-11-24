import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChromeSafariBrowserLauncher {
  static final ChromeSafariBrowserLauncher _instance =
      ChromeSafariBrowserLauncher._internal();

  factory ChromeSafariBrowserLauncher() {
    return _instance;
  }

  ChromeSafariBrowserLauncher._internal();

  MyChromeSafariBrowser? _browser;
  MyChromeSafariBrowser get _browserInstance =>
      _browser ??= MyChromeSafariBrowser();
  VoidCallback? onBrowserClosed;

  Future<void> openBrowser({
    required String url,
    required BuildContext context,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context);

    final browser = _browserInstance;
    browser.setContext(context);
    browser.setLauncher(this);

    try {
      if (browser.browserOpened) {
        await browser.close();
      }

      final newUri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'customtab': 'true',
      });

      await browser.open(
        url: WebUri(newUri.toString()),
        settings: ChromeSafariBrowserSettings(
          shareState: CustomTabsShareState.SHARE_STATE_OFF,
          barCollapsingEnabled: true,
          showTitle: false,
          enableUrlBarHiding: true,
          isTrustedWebActivity: true,
          presentationStyle: ModalPresentationStyle.OVER_FULL_SCREEN,
        ),
      );
    } catch (_) {
      browser.dismissLoadingDialog();
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Future<void> closeBrowser() async {
    if (_browser != null && _browser!.browserOpened) {
      try {
        await _browser!.close();
      } catch (_) {}
    }
  }
}

class MyChromeSafariBrowser extends ChromeSafariBrowser {
  bool browserOpened = false;
  BuildContext? _context;
  ChromeSafariBrowserLauncher? _launcher;

  void setContext(BuildContext context) {
    _context = context;
  }

  void setLauncher(ChromeSafariBrowserLauncher launcher) {
    _launcher = launcher;
  }

  void dismissLoadingDialog() {
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pop();
      _context = null;
    }
  }

  @override
  void onOpened() {
    browserOpened = true;
    dismissLoadingDialog();
  }

  @override
  void onCompletedInitialLoad(bool? didLoadSuccessfully) {
    dismissLoadingDialog();
  }

  @override
  void onInitialLoadDidRedirect(WebUri? url) {
    if (url != null && url.toString().startsWith('banjarmasinpintar://close')) {
      if (browserOpened) {
        close();
        browserOpened = false;
      }
    }
  }

  @override
  void onClosed() {
    browserOpened = false;
    dismissLoadingDialog();
    _launcher?.onBrowserClosed?.call();
  }
}
