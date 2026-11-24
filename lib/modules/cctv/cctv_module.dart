import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/layanan_app.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/models/cctv_category.dart';
import '/modules/cctv/models/cctv_wilayah.dart';
import '/modules/cctv/networking/cctv_api_service.dart';
import '/modules/cctv/pages/cctv_page.dart';
import '/modules/native_service_module.dart';

class CctvModule extends NativeServiceModule {
  @override
  String get slug => 'cctv';

  @override
  void registerRoutes(NyRouter router) {
    router.add(CctvPage.path);
  }

  @override
  Map<Type, dynamic> get modelDecoders => {
        List<CctvCamera>: (data) => CctvCamera.listFromGeoJson(data),
        List<CctvCategory>: (data) => CctvCategory.listFromResponse(data),
        List<CctvKecamatan>: (data) => CctvKecamatan.listFromResponse(data),
      };

  @override
  Map<Type, dynamic> get apiDecoders => {
        CctvApiService: () => CctvApiService(),
      };

  @override
  Future<void> open(BuildContext context, LayananApp app) async {
    await routeTo(CctvPage.path, data: app);
  }
}
