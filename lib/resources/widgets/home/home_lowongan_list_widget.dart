import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lowongan.dart';
import '/app/networking/karier_api_service.dart';
import '/app/services/chrome_safari_browser_service.dart';

class HomeLowonganListWidget extends StatefulWidget {
  final bool isScrollEnabled;

  const HomeLowonganListWidget({super.key, this.isScrollEnabled = true});

  @override
  State<HomeLowonganListWidget> createState() => _HomeLowonganListWidgetState();
}

class _HomeLowonganListWidgetState extends NyState<HomeLowonganListWidget> {
  static const int _initialLimit = 6;
  List<Lowongan> _allLowongans = [];
  List<Lowongan> _visibleLowongans = [];
  bool _hasMoreLowongans = true;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        if (widget.isScrollEnabled) {
          _scrollController.addListener(_onScroll);
        }
        _fetchLowongans();
      };

  @override
  void dispose() {
    if (widget.isScrollEnabled) {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreLowongans();
    }
  }

  Future<void> _fetchLowongans() async {
    setState(() => _loading = true);
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
        showToastDanger(title: 'Error', description: e.toString());
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

  @override
  Widget view(BuildContext context) {
    if (_loading) {
      return Skeletonizer(
        enabled: _loading,
        child: _buildSkeletonList(),
      );
    }

    return _visibleLowongans.isNotEmpty
        ? _buildLowonganList(context)
        : const Center(
            child: Text('Tidak ada lowongan ditemukan'),
          );
  }

  Widget _buildSkeletonList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 196,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 265,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLowonganList(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.isScrollEnabled ? _scrollController : null,
      physics: widget.isScrollEnabled
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(
            height: 204,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: _visibleLowongans.length,
              itemBuilder: (context, index) {
                return _buildListItem(context, _visibleLowongans[index]);
              },
            ),
          ),
          if (_hasMoreLowongans && widget.isScrollEnabled)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Lowongan lowongan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final dividerColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.18 : 0.12);
    final logoBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF8FAFC);

    final bool isGajiValid = lowongan.gaji_minimum != null &&
        lowongan.gaji_maksimum != null &&
        lowongan.gaji_minimum!.trim().isNotEmpty &&
        lowongan.gaji_maksimum!.trim().isNotEmpty &&
        lowongan.gaji_minimum!.trim() != '0' &&
        lowongan.gaji_maksimum!.trim() != '0';

    final salaryBg = isGajiValid
        ? (isDark
            ? const Color(0xFF16A34A).withValues(alpha: 0.18)
            : const Color(0xFFECFDF5))
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFF1F5F9));
    final salaryColor = isGajiValid
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : mutedColor;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.72).clamp(248.0, 280.0);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? theme.dividerColor.withValues(alpha: 0.16)
              : const Color(0xFFEEF2F7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ChromeSafariBrowserLauncher().openBrowser(
              url: lowongan.url ?? '',
              context: context,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: logoBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: dividerColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: lowongan.logo_perusahaan ?? '',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.business_rounded,
                          color: mutedColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (lowongan.judul ?? 'Tanpa judul').trim(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (lowongan.nama_perusahaan ?? '-').trim(),
                            style: TextStyle(
                              color: accentBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: mutedColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (lowongan.lokasi ?? '-').trim(),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: salaryBg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        isGajiValid
                            ? 'Rp ${lowongan.gaji_minimum} - ${lowongan.gaji_maksimum}'
                            : 'Gaji Dirahasiakan',
                        style: TextStyle(
                          color: salaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Divider(height: 1, thickness: 0.7, color: dividerColor),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (lowongan.tanggal_posting ?? '').trim(),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Banjarmasin Karir',
                      style: TextStyle(
                        color: accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
