import 'package:flutter/material.dart';
import '/modules/cctv/controllers/cctv_controller.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvFilterBar extends StatefulWidget {
  final CctvController controller;

  const CctvFilterBar({
    super.key,
    required this.controller,
  });

  @override
  State<CctvFilterBar> createState() => _CctvFilterBarState();
}

class _CctvFilterBarState extends State<CctvFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void didUpdateWidget(covariant CctvFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.controller.searchQuery) {
      _searchController.text = widget.controller.searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showKecamatanSheet() async {
    final ctrl = widget.controller;
    final options = ctrl.kecamatanOptions;
    final unassigned = ctrl.unassignedWilayahCount;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WilayahPickerSheet(
        title: 'Pilih Kecamatan',
        allLabel: 'Semua Kecamatan (${ctrl.categoryFilteredList.length})',
        selectedValue: ctrl.selectedKecamatan ?? '',
        items: [
          for (final opt in options)
            _PickerOption(
              value: opt.kecamatan.uuid,
              label: opt.kecamatan.namaKecamatan,
              count: opt.count,
            ),
          if (unassigned > 0)
            _PickerOption(
              value: CctvController.unassignedWilayahValue,
              label: 'Belum Terpetakan',
              count: unassigned,
            ),
        ],
      ),
    );

    if (selected != null) {
      ctrl.selectKecamatan(selected.isEmpty ? null : selected);
    }
  }

  Future<void> _showKelurahanSheet() async {
    final ctrl = widget.controller;
    if (!ctrl.canSelectKelurahan) return;
    final options = ctrl.kelurahanOptions;
    final total = options.fold<int>(0, (sum, o) => sum + o.count);

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WilayahPickerSheet(
        title: 'Pilih Kelurahan',
        allLabel: 'Semua Kelurahan ($total)',
        selectedValue: ctrl.selectedKelurahan ?? '',
        items: [
          for (final opt in options)
            _PickerOption(
              value: opt.kelurahan.uuid,
              label: opt.kelurahan.nama,
              count: opt.count,
            ),
        ],
      ),
    );

    if (selected != null) {
      ctrl.selectKelurahan(selected.isEmpty ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final tokens = CctvTokens.of(context);

    final kecText = ctrl.selectedKecamatanLabel.isNotEmpty
        ? ctrl.selectedKecamatanLabel
        : 'Semua Kecamatan (${ctrl.categoryFilteredList.length})';
    final kelTotal =
        ctrl.kelurahanOptions.fold<int>(0, (sum, o) => sum + o.count);
    final kelText = !ctrl.canSelectKelurahan
        ? 'Pilih kecamatan dulu'
        : (ctrl.selectedKelurahanLabel.isNotEmpty
            ? ctrl.selectedKelurahanLabel
            : 'Semua Kelurahan ($kelTotal)');

    final kecButton = _SelectorButton(
      icon: Icons.location_city_rounded,
      label: kecText,
      active: ctrl.selectedKecamatan != null,
      enabled: true,
      tokens: tokens,
      onTap: _showKecamatanSheet,
    );

    final kelButton = _SelectorButton(
      icon: Icons.location_on_outlined,
      label: kelText,
      active: ctrl.selectedKelurahan != null,
      enabled: ctrl.canSelectKelurahan,
      tokens: tokens,
      onTap: _showKelurahanSheet,
    );

    final searchField = SizedBox(
      height: CctvTokens.minTouchTarget,
      child: TextField(
        controller: _searchController,
        onChanged: ctrl.setSearchQuery,
        style: TextStyle(fontSize: 13, color: tokens.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari nama kamera, alamat, wilayah...',
          hintStyle: TextStyle(fontSize: 12.5, color: tokens.textMuted),
          prefixIcon:
              Icon(Icons.search_rounded, size: 18, color: tokens.textMuted),
          suffixIcon: ctrl.searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ctrl.setSearchQuery('');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: tokens.textMuted,
                  ),
                  tooltip: 'Hapus pencarian',
                )
              : null,
          filled: true,
          fillColor: tokens.surfaceSubtle,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
            borderSide: BorderSide(color: tokens.primary, width: 1.3),
          ),
        ),
      ),
    );

    final resetButton = SizedBox(
      height: CctvTokens.minTouchTarget,
      child: TextButton.icon(
        onPressed: () {
          _searchController.clear();
          ctrl.resetFilters();
        },
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text(
          'Reset',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: tokens.offlineText,
          backgroundColor: tokens.offlineSoft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isVeryNarrow = width < 360;
          final isWideDesktop = width >= 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Soft Category Pills
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryPill(
                      label: 'Semua (${ctrl.wilayahFilteredList.length})',
                      selected: ctrl.selectedCategory == null,
                      tokens: tokens,
                      onTap: () => ctrl.selectCategory(null),
                    ),
                    const SizedBox(width: 8),
                    for (final cat in ctrl.categories) ...[
                      _CategoryPill(
                        label:
                            '${cat.displayName} (${ctrl.countForCategory(cat.uuid)})',
                        selected: ctrl.selectedCategory == cat.uuid,
                        tokens: tokens,
                        onTap: () => ctrl.selectCategory(cat.uuid),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Row 2: Adaptive Search + Wilayah controls
              if (isWideDesktop)
                Row(
                  children: [
                    Expanded(flex: 3, child: kecButton),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: kelButton),
                    const SizedBox(width: 10),
                    Expanded(flex: 5, child: searchField),
                    if (ctrl.hasActiveFilters) ...[
                      const SizedBox(width: 10),
                      resetButton,
                    ],
                  ],
                )
              else if (isVeryNarrow) ...[
                searchField,
                const SizedBox(height: 8),
                kecButton,
                const SizedBox(height: 8),
                kelButton,
                if (ctrl.hasActiveFilters) ...[
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: resetButton),
                ],
              ] else ...[
                Row(
                  children: [
                    Expanded(child: searchField),
                    if (ctrl.hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      resetButton,
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: kecButton),
                    const SizedBox(width: 8),
                    Expanded(child: kelButton),
                  ],
                ),
              ],

              // Active Filter Summary
              if (ctrl.hasActiveFilters) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: tokens.caption.copyWith(fontSize: 12),
                        children: [
                          const TextSpan(text: 'Menampilkan '),
                          TextSpan(
                            text: '${ctrl.filteredCameras.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const TextSpan(text: ' dari '),
                          TextSpan(
                            text: '${ctrl.cameras.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const TextSpan(text: ' kamera'),
                        ],
                      ),
                    ),
                    if (ctrl.selectedKecamatanLabel.isNotEmpty)
                      _RemovableFilterChip(
                        label: ctrl.selectedKecamatanLabel,
                        tokens: tokens,
                        onRemove: () => ctrl.selectKecamatan(null),
                      ),
                    if (ctrl.selectedKelurahanLabel.isNotEmpty)
                      _RemovableFilterChip(
                        label: ctrl.selectedKelurahanLabel,
                        tokens: tokens,
                        onRemove: () => ctrl.selectKelurahan(null),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? tokens.primary : tokens.surfaceSubtle;
    final fg = selected ? tokens.primaryOnFill : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(CctvTokens.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CctvTokens.radiusPill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = !enabled
        ? tokens.textMuted
        : (active ? tokens.primary : tokens.textPrimary);

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Material(
        color: active ? tokens.primarySoft : tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          child: Container(
            height: CctvTokens.minTouchTarget,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
              border: active
                  ? Border.all(color: tokens.primary.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? tokens.primary : tokens.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemovableFilterChip extends StatelessWidget {
  final String label;
  final CctvTokens tokens;
  final VoidCallback onRemove;

  const _RemovableFilterChip({
    required this.label,
    required this.tokens,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: tokens.primarySoft,
        borderRadius: BorderRadius.circular(CctvTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.primary,
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: tokens.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerOption {
  final String value;
  final String label;
  final int count;

  const _PickerOption({
    required this.value,
    required this.label,
    required this.count,
  });
}

class _WilayahPickerSheet extends StatefulWidget {
  final String title;
  final String allLabel;
  final String selectedValue;
  final List<_PickerOption> items;

  const _WilayahPickerSheet({
    required this.title,
    required this.allLabel,
    required this.selectedValue,
    required this.items,
  });

  @override
  State<_WilayahPickerSheet> createState() => _WilayahPickerSheetState();
}

class _WilayahPickerSheetState extends State<_WilayahPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);
    final filtered = _query.trim().isEmpty
        ? widget.items
        : widget.items
            .where((o) =>
                o.label.toLowerCase().contains(_query.trim().toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: tokens.heading),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (widget.items.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: tokens.surfaceSubtle,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Divider(height: 1, color: tokens.divider),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (_query.trim().isEmpty)
                    ListTile(
                      title: Text(
                        widget.allLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: widget.selectedValue.isEmpty
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: widget.selectedValue.isEmpty
                              ? tokens.primary
                              : tokens.textPrimary,
                        ),
                      ),
                      trailing: widget.selectedValue.isEmpty
                          ? Icon(Icons.check_rounded, color: tokens.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(''),
                    ),
                  for (final opt in filtered)
                    ListTile(
                      title: Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: widget.selectedValue == opt.value
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: widget.selectedValue == opt.value
                              ? tokens.primary
                              : tokens.textPrimary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${opt.count}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                          if (widget.selectedValue == opt.value) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_rounded, color: tokens.primary),
                          ],
                        ],
                      ),
                      onTap: () => Navigator.of(context).pop(opt.value),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
