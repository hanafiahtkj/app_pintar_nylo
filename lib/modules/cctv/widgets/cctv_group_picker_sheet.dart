import 'package:flutter/material.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

Future<CctvCamera?> showCctvGroupPickerSheet({
  required BuildContext context,
  required List<CctvCamera> cameras,
  required String? activeCameraId,
  required Map<String, bool> aliveStatus,
}) {
  return showModalBottomSheet<CctvCamera>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _CctvGroupPickerSheet(
      cameras: cameras,
      activeCameraId: activeCameraId,
      aliveStatus: aliveStatus,
    ),
  );
}

class _CctvGroupPickerSheet extends StatelessWidget {
  final List<CctvCamera> cameras;
  final String? activeCameraId;
  final Map<String, bool> aliveStatus;

  const _CctvGroupPickerSheet({
    required this.cameras,
    required this.activeCameraId,
    required this.aliveStatus,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilih Kamera', style: tokens.heading),
                      const SizedBox(height: 2),
                      Text(
                        '${cameras.length} kamera di lokasi yang sama',
                        style: tokens.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.divider),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              itemCount: cameras.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final cam = cameras[index];
                final isSelected = cam.id == activeCameraId;
                final status = aliveStatus[cam.id];

                final Color iconBg;
                final Color iconFg;
                if (status == true) {
                  iconBg = tokens.onlineSoft;
                  iconFg = tokens.onlineText;
                } else if (status == false) {
                  iconBg = tokens.offlineSoft;
                  iconFg = tokens.offlineText;
                } else {
                  iconBg = tokens.surfaceSubtle;
                  iconFg = tokens.textMuted;
                }

                return Material(
                  color: isSelected ? tokens.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(cam),
                    borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? tokens.primary.withValues(alpha: 0.45)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius:
                                  BorderRadius.circular(CctvTokens.radiusSm),
                            ),
                            child: Icon(
                              Icons.videocam_outlined,
                              color: iconFg,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        cam.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (status != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: status
                                              ? tokens.online
                                              : tokens.offline,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (cam.wilayahLabel.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    cam.wilayahLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: tokens.primary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  cam.address.isNotEmpty
                                      ? cam.address
                                      : cam.displayCategory,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tokens.caption,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: tokens.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
