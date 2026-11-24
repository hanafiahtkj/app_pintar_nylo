import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/providers/firebase_messaging_provider.dart';
import '/config/storage_keys.dart';

class NotificationSettingsPage extends NyStatefulWidget {
  static RouteView path = (
    '/notification-settings',
    (_) => NotificationSettingsPage(),
  );

  NotificationSettingsPage({super.key})
      : super(child: () => _NotificationSettingsPageState());
}

class _NotificationSettingsPageState extends NyPage<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _isSaving = false;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () async {
        _pushEnabled = await StorageKeysConfig.pushNotificationsEnabled
                .read<bool>(defaultValue: true) ??
            true;
        if (mounted) setState(() {});
      };

  Future<void> _onTogglePush(bool value) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _pushEnabled = value;
    });
    try {
      await FirebaseMessagingService().handleNotificationToggle(value);
    } catch (_) {
      if (mounted) {
        setState(() => _pushEnabled = !value);
        showToastDanger(
          title: 'Gagal Menyimpan',
          description: 'Tidak dapat mengubah pengaturan notifikasi saat ini.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFAFBFE),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: false,
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 24 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'PREFERENSI SISTEM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Container(
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
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color:
                              accentBlue.withValues(alpha: isDark ? 0.16 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: accentBlue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Notifikasi Push',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Terima pemberitahuan tentang layanan, berita, dan info penting.',
                          style: TextStyle(
                            fontSize: 13,
                            color: mutedColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                      activeThumbColor: Colors.white,
                      activeTrackColor: accentBlue,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFE2E8F0),
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                      value: _pushEnabled,
                      onChanged: _isSaving ? null : _onTogglePush,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notifikasi push mencakup pengumuman resmi, informasi layanan, dan berita penting Pemerintah Kota Banjarmasin. Anda dapat mengubah preferensi ini kapan saja.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: mutedColor,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
