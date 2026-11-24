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
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          1,
          (index) => Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),
            ),
            height: 200,
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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
    final browserLauncher = ChromeSafariBrowserLauncher();

    bool isGajiValid = lowongan.gaji_minimum != null &&
        lowongan.gaji_maksimum != null &&
        lowongan.gaji_minimum != '0' &&
        lowongan.gaji_maksimum != '0';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.82).clamp(250.0, 300.0);

    return GestureDetector(
      onTap: () {
        browserLauncher.openBrowser(
          url: lowongan.url ?? '',
          context: context,
        );
      },
      child: Container(
        width: cardWidth,
        height: 260,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: lowongan.logo_perusahaan ?? '',
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.business,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lowongan.judul ?? 'No title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          lowongan.nama_perusahaan ?? 'No company',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lowongan.lokasi ?? 'No location',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isGajiValid
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isGajiValid
                          ? 'Rp ${lowongan.gaji_minimum} - ${lowongan.gaji_maksimum}'
                          : 'Gaji Dirahasiakan',
                      style: TextStyle(
                        color: isGajiValid
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lowongan.tanggal_posting ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    'Banjarmasin Karir',
                    style: TextStyle(
                      color: Colors.blue.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
