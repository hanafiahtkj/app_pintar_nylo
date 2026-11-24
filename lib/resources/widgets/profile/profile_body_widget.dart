import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:nylo_framework/theme/helper/ny_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import '/app/events/login_success_event.dart';
import '/app/events/logout_event.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/auth_service.dart';
import '/app/services/chrome_safari_browser_service.dart';
import '/config/app.dart';
import '/config/storage_keys.dart';
import '/resources/pages/login_page.dart';
import '/resources/pages/notification_settings_page.dart';

class ProfileBodyWidget extends StatefulWidget {
  final VoidCallback? onLogout;
  final String? initialHotline;

  const ProfileBodyWidget({
    super.key,
    this.onLogout,
    this.initialHotline,
  });

  @override
  State<ProfileBodyWidget> createState() => _ProfileBodyWidgetState();
}

class _ProfileBodyWidgetState extends NyState<ProfileBodyWidget> {
  bool _darkMode = false;
  String? _hotline;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () async {
        _hotline = widget.initialHotline;
        _darkMode = NyTheme.isDark();

        listen<LoginSuccessEvent>((_) {
          if (mounted) setState(() {});
        });

        listen<LogoutEvent>((_) {
          if (mounted) setState(() {});
        });

        if (mounted) setState(() {});
      };

  @override
  void didUpdateWidget(covariant ProfileBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHotline != null &&
        widget.initialHotline != oldWidget.initialHotline) {
      _hotline = widget.initialHotline;
    }
  }

  void _launchSSO() {
    if (Platform.isIOS) {
      routeTo(LoginPage.path);
    } else {
      final browserLauncher = ChromeSafariBrowserLauncher();
      browserLauncher.openBrowser(
        url: AppConfig.ssoRegisUrl,
        context: context,
      );
    }
  }

  void _showTentangDialog() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentBlue.withValues(alpha: isDark ? 0.18 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 28,
                      color: accentBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplikasi Banjarmasin Pintar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi ${packageInfo.version}',
                    style: TextStyle(
                      fontSize: 13,
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: theme.dividerColor
                        .withValues(alpha: isDark ? 0.22 : 0.14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplikasi layanan publik terpadu Pemerintah Kota Banjarmasin. '
                    'Menyediakan akses mudah ke berbagai layanan pemerintahan, '
                    'berita, lowongan kerja, dan informasi penting lainnya.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: isDark
                          ? Colors.grey.shade300
                          : const Color(0xFF475569),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openWhatsApp() async {
    if (_hotline == null || _hotline!.isEmpty) {
      final hotlineObj =
          await api<PintarApiService>((request) => request.getHotline());
      _hotline = hotlineObj?.text;
    }
    if (_hotline == null || _hotline!.isEmpty) return;

    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: _hotline,
      queryParameters: {'text': ''},
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }

  @override
  Widget view(BuildContext context) {
    if (!AuthService().isLoggedIn) {
      return _buildLoginPrompt();
    }
    return _buildProfileContent();
  }

  Widget _buildLoginPrompt() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isWide ? 24 : 20,
          24,
          isWide ? 24 : 20,
          isWide ? 32 : 96,
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
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
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
                    Icons.person_outline_rounded,
                    size: 28,
                    color: accentBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Masuk untuk Melihat Profil',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Akses profil akun, pengaturan notifikasi, dan layanan terpadu Pemerintah Kota Banjarmasin.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: mutedColor,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSSOButton(accentBlue, isDark),
                if (Platform.isIOS || Platform.isMacOS) ...[
                  const SizedBox(height: 12),
                  _buildAppleButton(isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSSOButton(Color accentBlue, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _launchSSO,
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

  Widget _buildAppleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: SignInWithAppleButton(
        onPressed: () {
          routeTo(LoginPage.path);
        },
        height: 50,
        borderRadius: BorderRadius.circular(12),
        style: isDark
            ? SignInWithAppleButtonStyle.white
            : SignInWithAppleButtonStyle.black,
      ),
    );
  }

  Widget _buildProfileContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final user = AuthService().currentUser;
    final isAsn = user != null &&
        user.employeeIdNumber != null &&
        user.employeeIdNumber!.isNotEmpty;

    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);
    final destructiveRed =
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

    final badgeBg = isAsn
        ? (isDark
            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
            : const Color(0xFFFEF3C7))
        : (isDark
            ? const Color(0xFF16A34A).withValues(alpha: 0.2)
            : const Color(0xFFDCFCE7));
    final badgeFg = isAsn
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D));

    final infoRows = <Widget>[
      if (user != null && user.email != null && user.email!.isNotEmpty)
        _buildInfoRow(
          Icons.email_outlined,
          'Email',
          user.email!,
          accentBlue,
          mutedColor,
          isDark,
        ),
      if (user != null &&
          user.nationalIdNumber != null &&
          user.nationalIdNumber!.isNotEmpty)
        _buildInfoRow(
          Icons.credit_card_outlined,
          'NIK',
          user.nationalIdNumber!,
          accentBlue,
          mutedColor,
          isDark,
        ),
      if (user != null &&
          user.whatsAppNumber != null &&
          user.whatsAppNumber!.isNotEmpty)
        _buildInfoRow(
          Icons.phone_android_outlined,
          'No. WA',
          user.whatsAppNumber!,
          accentBlue,
          mutedColor,
          isDark,
        ),
      if (user != null &&
          user.employeeIdNumber != null &&
          user.employeeIdNumber!.isNotEmpty)
        _buildInfoRow(
          Icons.badge_outlined,
          'NIP',
          user.employeeIdNumber!,
          accentBlue,
          mutedColor,
          isDark,
        ),
    ];

    return ColoredBox(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFAFBFE),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isWide ? 24 : 16,
          16,
          isWide ? 24 : 16,
          isWide ? 36 : 96,
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue
                                  .withValues(alpha: isDark ? 0.2 : 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: accentBlue
                              .withValues(alpha: isDark ? 0.2 : 0.1),
                          child: Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: accentBlue,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      (user?.name ?? '').trim().isNotEmpty
                          ? user!.name!.trim()
                          : 'Pengguna',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAsn ? 'ASN' : 'UMUM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (infoRows.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionLabel('INFORMASI AKUN', mutedColor),
                  const SizedBox(height: 8),
                  _buildSurfaceCard(
                    theme: theme,
                    isDark: isDark,
                    borderColor: borderColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < infoRows.length; i++) ...[
                            infoRows[i],
                            if (i < infoRows.length - 1)
                              Divider(
                                height: 1,
                                indent: 50,
                                color: borderColor,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildSectionLabel('PENGATURAN & INFORMASI', mutedColor),
                const SizedBox(height: 8),
                _buildSurfaceCard(
                  theme: theme,
                  isDark: isDark,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      _buildProfileMenu(
                        icon: Icons.notifications_outlined,
                        title: 'Pengaturan Notifikasi',
                        accentColor: accentBlue,
                        mutedColor: mutedColor,
                        isDark: isDark,
                        onTap: () {
                          routeTo(NotificationSettingsPage.path);
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 62,
                        endIndent: 16,
                        color: borderColor,
                      ),
                      _buildProfileMenu(
                        icon: Icons.dark_mode_outlined,
                        title: 'Tema Gelap',
                        accentColor: accentBlue,
                        mutedColor: mutedColor,
                        isDark: isDark,
                        trailing: Switch(
                          activeThumbColor: Colors.white,
                          activeTrackColor: accentBlue,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : const Color(0xFFE2E8F0),
                          trackOutlineColor:
                              WidgetStateProperty.all(Colors.transparent),
                          value: _darkMode,
                          onChanged: (val) async {
                            setState(() => _darkMode = val);
                            await StorageKeysConfig.isDarkMode.save(
                              val,
                              inBackpack: true,
                            );
                            if (mounted) {
                              await NyTheme.set(
                                context,
                                id: val ? 'dark_theme' : 'light_theme',
                              );
                            }
                          },
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 62,
                        endIndent: 16,
                        color: borderColor,
                      ),
                      _buildProfileMenu(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang Aplikasi',
                        accentColor: accentBlue,
                        mutedColor: mutedColor,
                        isDark: isDark,
                        onTap: _showTentangDialog,
                      ),
                      Divider(
                        height: 1,
                        indent: 62,
                        endIndent: 16,
                        color: borderColor,
                      ),
                      _buildProfileMenu(
                        icon: Icons.help_outline_rounded,
                        title: 'Bantuan',
                        accentColor: accentBlue,
                        mutedColor: mutedColor,
                        isDark: isDark,
                        onTap: _openWhatsApp,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSurfaceCard(
                  theme: theme,
                  isDark: isDark,
                  borderColor: borderColor,
                  child: _buildProfileMenu(
                    icon: Icons.logout_rounded,
                    title: 'Keluar',
                    accentColor: accentBlue,
                    mutedColor: mutedColor,
                    isDark: isDark,
                    textColor: destructiveRed,
                    iconColor: destructiveRed,
                    hideArrow: true,
                    onTap: _showLogoutDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: mutedColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSurfaceCard({
    required ThemeData theme,
    required bool isDark,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: borderColor) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDark ? 0.2 : 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String text,
    Color accentBlue,
    Color mutedColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentBlue.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Color mutedColor,
    required bool isDark,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    bool hideArrow = false,
    VoidCallback? onTap,
  }) {
    final resolvedIconColor = iconColor ?? accentColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: resolvedIconColor.withValues(alpha: isDark ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: resolvedIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing ??
          (hideArrow
              ? null
              : Icon(Icons.chevron_right_rounded, color: mutedColor)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final destructiveRed =
        isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: const Text(
            'Anda perlu masuk kembali menggunakan akun SSO untuk mengakses layanan terpadu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
                widget.onLogout?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: destructiveRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}
