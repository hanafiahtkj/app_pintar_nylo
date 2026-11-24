import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
      _showErrorSnackBar(context, 'Tautan tidak valid atau tidak tersedia.');
      return;
    }

    if (!context.mounted) return;

    final browser = _browserInstance;
    browser.setContext(context);
    browser.setLauncher(this);
    browser.showLoadingDialog(context);

    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'customtab': 'true',
    });

    try {
      if (browser.browserOpened) {
        await browser.close();
      }

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
      final launched = await _launchExternalFallback(newUri);
      if (!launched && context.mounted) {
        _showErrorSnackBar(
          context,
          'Tidak dapat membuka tautan. Pastikan browser tersedia di perangkat Anda.',
        );
      }
    }
  }

  Future<bool> _launchExternalFallback(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
  bool _isLoadingDialogShowing = false;
  Timer? _loadingTimeoutTimer;
  BuildContext? _context;
  ChromeSafariBrowserLauncher? _launcher;

  void setContext(BuildContext context) {
    _context = context;
  }

  void setLauncher(ChromeSafariBrowserLauncher launcher) {
    _launcher = launcher;
  }

  void showLoadingDialog(BuildContext context) {
    if (_isLoadingDialogShowing || !context.mounted) return;
    _isLoadingDialogShowing = true;
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(
      const Duration(seconds: 10),
      dismissLoadingDialog,
    );

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    ).whenComplete(() {
      _isLoadingDialogShowing = false;
      _loadingTimeoutTimer?.cancel();
    });
  }

  void dismissLoadingDialog() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    if (!_isLoadingDialogShowing) return;
    _isLoadingDialogShowing = false;

    final ctx = _context;
    _context = null;
    if (ctx != null && ctx.mounted) {
      final navigator = Navigator.of(ctx, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
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
