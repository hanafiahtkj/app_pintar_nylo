import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '/app/events/login_success_event.dart';
import '/app/services/auth_service.dart';
import '/app/services/chrome_safari_browser_service.dart';
import '/app/services/pending_app_service.dart';
import '/config/app.dart';
import '/config/storage_keys.dart';

class LoginPage extends NyStatefulWidget {
  static RouteView path = ('/login', (_) => LoginPage());

  LoginPage({super.key}) : super(child: () => _LoginPageState());
}

class _LoginPageState extends NyPage<LoginPage> {
  bool _isAppleLoading = false;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        listen<LoginSuccessEvent>((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      };

  void _launchSSO(BuildContext context) {
    final browserLauncher = ChromeSafariBrowserLauncher();
    browserLauncher.openBrowser(
      url: AppConfig.ssoRegisUrl,
      context: context,
    );
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (_isAppleLoading) return;
    setState(() => _isAppleLoading = true);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final appleId = credential.userIdentifier;
      final password = credential.authorizationCode;
      final appleNameParts = [
        if (credential.givenName != null) credential.givenName,
        if (credential.familyName != null) credential.familyName,
      ];
      final appleName =
          appleNameParts.isNotEmpty ? appleNameParts.join(' ') : null;
      final email = credential.email;

      final savedAppleName = await StorageKeysConfig.appleName.read<String>();
      final name = appleName ?? savedAppleName;

      if (appleName != null) {
        await StorageKeysConfig.appleName.save(appleName);
      }

      if (appleId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendapatkan Apple ID')),
          );
        }
        return;
      }

      final user = await AuthService().loginWithApple(
        appleId: appleId,
        password: password,
        name: name,
        email: email,
      );

      if (user != null) {
        PendingAppService().showPendingAppDialogIfNeeded();
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Apple gagal. Silakan coba lagi.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Apple gagal. Periksa koneksi Anda dan coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 20,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isWide ? 28 : 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentBlue.withValues(alpha: isDark ? 0.18 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 28,
                        color: accentBlue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Masuk ke Banjarmasin Pintar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gunakan akun SSO Kota Banjarmasin untuk mengakses layanan terpadu.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: mutedColor,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _buildSSOButton(context, accentBlue, isDark),
                    if (Platform.isIOS || Platform.isMacOS) ...[
                      const SizedBox(height: 12),
                      _buildAppleButton(context, isDark),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: mutedColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Dilindungi SSO Pemerintah Kota Banjarmasin',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSSOButton(
    BuildContext context,
    Color accentBlue,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _isAppleLoading ? null : () => _launchSSO(context),
        icon: const Icon(Icons.login_rounded, size: 20),
        label: const Text(
          'Masuk dengan SSO',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton(BuildContext context, bool isDark) {
    if (_isAppleLoading) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: SignInWithAppleButton(
        onPressed: () => _signInWithApple(context),
        height: 50,
        borderRadius: BorderRadius.circular(12),
        style: isDark
            ? SignInWithAppleButtonStyle.white
            : SignInWithAppleButtonStyle.black,
      ),
    );
  }
}
