import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/notification_item.dart';
import '/app/services/chrome_safari_browser_service.dart';

class NotificationDetailPage extends NyStatefulWidget {
  static RouteView path = (
    '/notification-detail',
    (_) => NotificationDetailPage(),
  );

  final NotificationItem? item;

  NotificationDetailPage({super.key, this.item})
      : super(child: () => _NotificationDetailPageState());
}

class _NotificationDetailPageState extends NyPage<NotificationDetailPage> {
  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  NotificationItem _resolveItem() {
    if (widget.item != null) return widget.item!;
    final raw = data();
    if (raw is NotificationItem) return raw;
    if (raw is Map && raw['item'] is NotificationItem) {
      return raw['item'] as NotificationItem;
    }
    if (raw is Map) {
      return NotificationItem.fromJson(raw);
    }
    return NotificationItem();
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    return parsed != null ? Color(parsed) : const Color(0xFF1455D4);
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final item = _resolveItem();
    final color = _parseColor(item.color);

    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final titleColor = theme.textTheme.headlineSmall?.color ??
        (isDark ? Colors.white : const Color(0xFF0F172A));
    final bodyColor =
        isDark ? Colors.grey.shade200 : const Color(0xFF334155);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);

    final title = item.title.trim();
    final desc = item.desc.trim();
    final bodyHtml = (item.body ?? '').trim();
    final sourceApp = (item.sourceApp ?? '').trim();
    final hasContent = title.isNotEmpty || desc.isNotEmpty || bodyHtml.isNotEmpty;

    return Scaffold(
      backgroundColor: isWide && !isDark
          ? const Color(0xFFFAFBFE)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: false,
        title: const Text(
          'Detail Notifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: !hasContent
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: mutedColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detail notifikasi tidak ditemukan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 20,
                isWide ? 20 : 12,
                isWide ? 24 : 20,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    width: double.infinity,
                    padding: isWide ? const EdgeInsets.all(28) : EdgeInsets.zero,
                    decoration: isWide
                        ? BoxDecoration(
                            color: isDark ? theme.cardColor : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: isDark
                                ? Border.all(color: borderColor)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: isDark ? 0.2 : 0.045),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  color.withValues(alpha: isDark ? 0.2 : 0.12),
                              child: Icon(
                                item.isUrgent
                                    ? Icons.campaign_rounded
                                    : Icons.notifications_rounded,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (sourceApp.isNotEmpty)
                                    Text(
                                      sourceApp.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (item.time.trim().isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 13,
                                          color: mutedColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.time.trim(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mutedColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title.isNotEmpty ? title : 'Notifikasi',
                          style: TextStyle(
                            fontSize: isWide ? 22 : 20,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, thickness: 1, color: borderColor),
                        const SizedBox(height: 16),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 15,
                              color: bodyColor,
                              height: 1.65,
                            ),
                          ),
                        if (bodyHtml.isNotEmpty) ...[
                          if (desc.isNotEmpty) const SizedBox(height: 16),
                          HtmlWidget(
                            bodyHtml,
                            textStyle: TextStyle(
                              fontSize: 15,
                              color: bodyColor,
                              height: 1.7,
                            ),
                            onTapUrl: (url) async {
                              await ChromeSafariBrowserLauncher().openBrowser(
                                url: url,
                                context: context,
                              );
                              return true;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
