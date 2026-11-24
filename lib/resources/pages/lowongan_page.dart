import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lowongan.dart';
import '/app/networking/karier_api_service.dart';
import '/app/services/chrome_safari_browser_service.dart';

class LowonganPage extends NyStatefulWidget {
  static RouteView path = ('/lowongan', (_) => LowonganPage());

  LowonganPage({super.key}) : super(child: () => _LowonganPageState());
}

class _LowonganPageState extends NyPage<LowonganPage> {
  static const int _initialLimit = 9;
  List<Lowongan> _allLowongans = [];
  List<Lowongan> _visibleLowongans = [];
  bool _hasMoreLowongans = true;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _scrollController.addListener(_onScroll);
        _fetchLowongans();
      };

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLowongans();
    }
  }

  Future<void> _fetchLowongans() async {
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final result =
          await api<KarierApiService>((request) => request.getLowongans());
      if (mounted) {
        setState(() {
          _allLowongans = result ?? [];
          _visibleLowongans = _allLowongans.take(_initialLimit).toList();
          _hasMoreLowongans = _allLowongans.length > _visibleLowongans.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToastDanger(
          title: 'Gagal Memuat',
          description: 'Tidak dapat memuat daftar lowongan. Silakan coba lagi.',
        );
      }
    }
  }

  void _loadMoreLowongans() {
    if (_hasMoreLowongans) {
      final nextItems = _allLowongans
          .skip(_visibleLowongans.length)
          .take(_initialLimit)
          .toList();
      setState(() {
        _visibleLowongans.addAll(nextItems);
        _hasMoreLowongans = _allLowongans.length > _visibleLowongans.length;
      });
    }
  }

  int _resolveColumns(double maxWidth) {
    if (maxWidth >= 980) return 3;
    if (maxWidth >= 620) return 2;
    return 1;
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text(
          'Lowongan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: _buildBody(context, isDark),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final horizontalPad = isWide ? 24.0 : 16.0;

    if (_loading) {
      return Skeletonizer(
        enabled: true,
        child: _buildSkeletonGrid(context, horizontalPad, isDark),
      );
    }

    if (_visibleLowongans.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchLowongans,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _resolveColumns(constraints.maxWidth);
                final gap = columns > 1 ? 16.0 : 14.0;
                final itemWidth =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: _visibleLowongans
                          .map(
                            (lowongan) => SizedBox(
                              width: itemWidth,
                              child: _buildListItem(context, lowongan, isDark),
                            ),
                          )
                          .toList(),
                    ),
                    if (_hasMoreLowongans) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _loadMoreLowongans,
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          label: const Text('Muat Lebih Banyak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? const Color(0xFF6EA8FE)
                                : const Color(0xFF1455D4),
                            side: BorderSide(
                              color: (isDark
                                      ? const Color(0xFF6EA8FE)
                                      : const Color(0xFF1455D4))
                                  .withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work_outline_rounded,
              size: 48,
              color: mutedColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada lowongan tersedia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tarik ke bawah atau tekan tombol di bawah untuk memuat ulang.',
              style: TextStyle(fontSize: 13, color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchLowongans,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF6EA8FE)
                    : const Color(0xFF1455D4),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid(
    BuildContext context,
    double horizontalPad,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final surfacePlaceholder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = _resolveColumns(constraints.maxWidth);
              final gap = columns > 1 ? 16.0 : 14.0;
              final itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: List.generate(
                  6,
                  (_) => Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dividerColor
                            .withValues(alpha: isDark ? 0.22 : 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: surfacePlaceholder,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posisi Lowongan Pekerjaan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Nama Perusahaan',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Banjarmasin, Kalimantan Selatan',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Gaji Dirahasiakan',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Lowongan lowongan,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);
    final logoBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF8FAFC);

    final title = (lowongan.judul ?? '').trim();
    final company = (lowongan.nama_perusahaan ?? '').trim();
    final location = (lowongan.lokasi ?? '').trim();
    final postedDate = (lowongan.tanggal_posting ?? '').trim();

    final hasSalary = lowongan.gaji_minimum != null &&
        lowongan.gaji_maksimum != null &&
        lowongan.gaji_minimum!.trim().isNotEmpty &&
        lowongan.gaji_maksimum!.trim().isNotEmpty &&
        lowongan.gaji_minimum!.trim() != '0' &&
        lowongan.gaji_maksimum!.trim() != '0';

    final salaryText = hasSalary
        ? '${lowongan.gaji_minimum} - ${lowongan.gaji_maksimum}'
        : 'Gaji Dirahasiakan';

    final salaryBg = hasSalary
        ? (isDark
            ? const Color(0xFF16A34A).withValues(alpha: 0.18)
            : const Color(0xFFECFDF5))
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFF1F5F9));

    final salaryTextColor = hasSalary
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : mutedColor;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ChromeSafariBrowserLauncher().openBrowser(
            url: lowongan.url ?? '',
            context: context,
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: logoBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: lowongan.logo_perusahaan ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: logoBg,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.business_rounded,
                            size: 22,
                            color: mutedColor.withValues(alpha: 0.5),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: logoBg,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.business_rounded,
                            size: 22,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 40),
                            child: Text(
                              title.isNotEmpty ? title : 'Tanpa judul',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.isNotEmpty ? company : '-',
                            style: TextStyle(
                              color: accentBlue,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: mutedColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location.isNotEmpty ? location : 'Lokasi tidak dicantumkan',
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: salaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        salaryText,
                        style: TextStyle(
                          color: salaryTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (postedDate.isNotEmpty) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          postedDate,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Banjarmasin Karir',
                          style: TextStyle(
                            color: accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: accentBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
