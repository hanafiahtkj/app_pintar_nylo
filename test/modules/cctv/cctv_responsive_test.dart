import 'package:flutter_test/flutter_test.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:app_pintar_nylo/bootstrap/env.g.dart';
import 'package:app_pintar_nylo/bootstrap/providers.dart';
import 'package:app_pintar_nylo/modules/cctv/controllers/cctv_controller.dart';
import 'package:app_pintar_nylo/modules/cctv/models/cctv_camera.dart';
import 'package:app_pintar_nylo/modules/cctv/models/cctv_category.dart';
import 'package:app_pintar_nylo/modules/cctv/models/cctv_wilayah.dart';
import 'package:app_pintar_nylo/modules/cctv/pages/cctv_fullscreen_map_page.dart';
import 'package:app_pintar_nylo/modules/cctv/pages/cctv_page.dart';

CctvController _buildSampleController() {
  final controller = CctvController();
  controller.hydrate(
    cameras: [
      CctvCamera(
        id: 'cam-1',
        location: 'Simpang Lambung Mangkurat Utara Arah Jembatan Merdeka',
        address: 'Jl. Lambung Mangkurat No. 12, Banjarmasin Tengah',
        zone: 'atcs',
        categoryUuid: 'cat-1',
        kecamatanUuid: 'kec-1',
        kecamatanNama: 'Banjarmasin Tengah',
        kelurahanUuid: 'kel-1',
        kelurahanNama: 'Kertak Baru Ilir',
        latitude: -3.3201,
        longitude: 114.5902,
        hasValidCoords: true,
        videoUrl: null,
      ),
      CctvCamera(
        id: 'cam-2',
        location: 'Simpang Lambung Mangkurat Selatan',
        address: 'Jl. Lambung Mangkurat No. 14',
        zone: 'atcs',
        categoryUuid: 'cat-1',
        kecamatanUuid: 'kec-1',
        kecamatanNama: 'Banjarmasin Tengah',
        kelurahanUuid: 'kel-1',
        kelurahanNama: 'Kertak Baru Ilir',
        latitude: -3.3201,
        longitude: 114.5902,
        hasValidCoords: true,
        videoUrl: null,
      ),
      CctvCamera(
        id: 'cam-3',
        location: 'Siring Menara Pandang Tendean',
        address: 'Jl. Kapten Piere Tendean, Gadang, Banjarmasin Tengah',
        zone: 'ruang publik',
        categoryUuid: 'cat-2',
        kecamatanUuid: 'kec-1',
        kecamatanNama: 'Banjarmasin Tengah',
        kelurahanUuid: 'kel-2',
        kelurahanNama: 'Gadang',
        latitude: -3.3185,
        longitude: 114.5931,
        hasValidCoords: true,
        videoUrl: null,
      ),
      CctvCamera(
        id: 'cam-4',
        location: 'Kamera Gudang Pemko Tanpa Koordinat GPS',
        address: 'Komplek Balai Kota Banjarmasin',
        zone: 'publik',
        categoryUuid: 'cat-2',
        latitude: 0,
        longitude: 0,
        hasValidCoords: false,
        videoUrl: null,
      ),
    ],
    categories: [
      CctvCategory(uuid: 'cat-1', name: 'atcs'),
      CctvCategory(uuid: 'cat-2', name: 'ruang publik'),
    ],
    wilayah: [
      CctvKecamatan(
        uuid: 'kec-1',
        namaKecamatan: 'Banjarmasin Tengah',
        kelurahan: [
          CctvKelurahan(uuid: 'kel-1', nama: 'Kertak Baru Ilir'),
          CctvKelurahan(uuid: 'kel-2', nama: 'Gadang'),
        ],
      ),
    ],
    aliveStatus: {
      'cam-1': true,
      'cam-2': false,
      'cam-3': true,
      'cam-4': false,
    },
  );
  return controller;
}

void main() {
  NyTest.init();

  nySetUpAll(() async {
    NyEnvRegistry.register(getter: Env.get);
    await setupApplication(providers);
  });

  final viewports = <String, Size>{
    'Mobile 320x640': const Size(320, 640),
    'Mobile 390x844': const Size(390, 844),
    'Tablet 768x1024': const Size(768, 1024),
    'Desktop 1280x800': const Size(1280, 800),
    'Desktop 1440x900': const Size(1440, 900),
  };

  for (final entry in viewports.entries) {
    nyWidgetTest(
      'CctvPage renders cleanly without overflow on ${entry.key}',
      (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = _buildSampleController();
        addTearDown(controller.dispose);

        await tester.pumpNyWidgetSimple(CctvPage(cctvController: controller));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.text('Daftar Kamera'), findsOneWidget);
        expect(find.text('Grid'), findsNothing);
      },
    );

    nyWidgetTest(
      'CctvFullscreenMapPage renders cleanly without overflow on ${entry.key}',
      (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = _buildSampleController();
        addTearDown(controller.dispose);

        await tester.pumpNyWidgetSimple(
          CctvFullscreenMapPage(controller: controller),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.text('Putar'), findsOneWidget);
        expect(find.textContaining('Peta CCTV'), findsOneWidget);
      },
    );
  }
}
