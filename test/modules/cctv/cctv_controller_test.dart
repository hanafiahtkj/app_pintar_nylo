import 'package:flutter_test/flutter_test.dart';
import 'package:app_pintar_nylo/modules/cctv/controllers/cctv_controller.dart';
import 'package:app_pintar_nylo/modules/cctv/models/cctv_camera.dart';
import 'package:app_pintar_nylo/modules/cctv/models/cctv_category.dart';
import 'package:app_pintar_nylo/modules/cctv/models/cctv_wilayah.dart';

void main() {
  group('CctvCamera GeoJSON & Formatters', () {
    test('parses GeoJSON FeatureCollection and validates coordinates', () {
      final raw = {
        'msg': 'success',
        'data': {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {
                'uuid': 'cam-1',
                'name': 'simpang gerilya',
                'address': 'Jl. Gerilya No. 1',
                'latitude': '-3.331200',
                'longitude': '114.592300',
                'url': 'https://cctv.banjarmasinkota.go.id/hls/cam1.m3u8',
                'category': {'uuid': 'cat-atcs', 'name': 'atcs'},
                'kecamatan': {'uuid': 'kec-1', 'nama': 'Banjarmasin Selatan'},
                'kelurahan': {'uuid': 'kel-1', 'nama': 'Kelayan Timur'},
              },
            },
            {
              'type': 'Feature',
              'properties': {
                'uuid': 'cam-2',
                'name': 'Pasar Lama',
                'latitude': '0',
                'longitude': '0',
                'category': {'uuid': 'cat-pub', 'name': 'ruang publik'},
              },
            },
          ],
        },
      };

      final list = CctvCamera.listFromGeoJson(raw);
      expect(list.length, 2);

      expect(list[0].id, 'cam-1');
      expect(list[0].displayName, 'Simpang Gerilya');
      expect(list[0].displayCategory, 'ATCS');
      expect(list[0].wilayahLabel, 'Kel. Kelayan Timur, Kec. Banjarmasin Selatan');
      expect(list[0].hasValidCoords, isTrue);
      expect(list[0].coordsLabel, '-3.3312, 114.5923');

      expect(list[1].id, 'cam-2');
      expect(list[1].displayName, 'Pasar Lama');
      expect(list[1].displayCategory, 'Ruang Publik');
      expect(list[1].hasValidCoords, isFalse);
      expect(list[1].wilayahLabel, isEmpty);
    });
  });

  group('CctvController Filtering, Grouping & Auto-Scan', () {
    late CctvController controller;

    setUp(() {
      controller = CctvController();
      controller.hydrate(
        cameras: [
          CctvCamera(
            id: 'c1',
            location: 'Simpang Lambung Mangkurat 1',
            address: 'Jl. Lambung Mangkurat',
            zone: 'ATCS',
            categoryUuid: 'cat-1',
            kecamatanUuid: 'kec-tengah',
            kecamatanNama: 'Banjarmasin Tengah',
            kelurahanUuid: 'kel-kertak',
            kelurahanNama: 'Kertak Baru Ilir',
            latitude: -3.320100,
            longitude: 114.590200,
            hasValidCoords: true,
            videoUrl: 'https://example.com/1.m3u8',
          ),
          CctvCamera(
            id: 'c2',
            location: 'Simpang Lambung Mangkurat 2',
            address: 'Jl. Lambung Mangkurat',
            zone: 'ATCS',
            categoryUuid: 'cat-1',
            kecamatanUuid: 'kec-tengah',
            kecamatanNama: 'Banjarmasin Tengah',
            kelurahanUuid: 'kel-kertak',
            kelurahanNama: 'Kertak Baru Ilir',
            latitude: -3.320100,
            longitude: 114.590200,
            hasValidCoords: true,
            videoUrl: 'https://example.com/2.m3u8',
          ),
          CctvCamera(
            id: 'c3',
            location: 'Siring Menara Pandang',
            address: 'Jl. Piere Tendean',
            zone: 'Publik',
            categoryUuid: 'cat-2',
            kecamatanUuid: 'kec-tengah',
            kecamatanNama: 'Banjarmasin Tengah',
            kelurahanUuid: 'kel-gadang',
            kelurahanNama: 'Gadang',
            latitude: -3.318500,
            longitude: 114.593100,
            hasValidCoords: true,
            videoUrl: 'https://example.com/3.m3u8',
          ),
          CctvCamera(
            id: 'c4',
            location: 'Kamera Tanpa GPS',
            address: 'Gudang Pemko',
            zone: 'Publik',
            categoryUuid: 'cat-2',
            latitude: 0,
            longitude: 0,
            hasValidCoords: false,
            videoUrl: 'https://example.com/4.m3u8',
          ),
        ],
        categories: [
          CctvCategory(uuid: 'cat-1', name: 'atcs'),
          CctvCategory(uuid: 'cat-2', name: 'publik'),
        ],
        wilayah: [
          CctvKecamatan(
            uuid: 'kec-tengah',
            namaKecamatan: 'Banjarmasin Tengah',
            kelurahan: [
              CctvKelurahan(uuid: 'kel-kertak', nama: 'Kertak Baru Ilir'),
              CctvKelurahan(uuid: 'kel-gadang', nama: 'Gadang'),
            ],
          ),
        ],
        aliveStatus: {
          'c1': false,
          'c2': true,
          'c3': false,
        },
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('groups identical valid coordinates for map and keeps unmapped in grid',
        () {
      expect(controller.mapGroups.length, 2);
      expect(controller.mapGroups.first.isMultiCamera, isTrue);
      expect(controller.mapGroups.first.cameras.length, 2);
      // Group c1 (offline) + c2 (online) => online (true)
      expect(controller.mapGroups.first.aliveStatus(controller.aliveStatus),
          isTrue);
      // Group c3 (offline) => offline (false)
      expect(controller.mapGroups[1].aliveStatus(controller.aliveStatus),
          isFalse);

      // allGroups includes unmapped camera c4 for the camera list
      expect(controller.allGroups.length, 3);
      expect(controller.allGroups.last.hasValidCoords, isFalse);
    });

    test('supports cascading Kecamatan -> Kelurahan, unassigned, and search', () {
      expect(controller.canSelectKelurahan, isFalse);
      expect(controller.unassignedWilayahCount, 1);

      controller.selectKecamatan('kec-tengah');
      expect(controller.canSelectKelurahan, isTrue);
      expect(controller.filteredCameras.length, 3);
      expect(controller.kelurahanOptions.length, 2);

      controller.selectKelurahan('kel-gadang');
      expect(controller.filteredCameras.length, 1);
      expect(controller.filteredCameras.first.id, 'c3');

      controller.selectKecamatan(CctvController.unassignedWilayahValue);
      expect(controller.selectedKelurahan, isNull);
      expect(controller.canSelectKelurahan, isFalse);
      expect(controller.filteredCameras.length, 1);
      expect(controller.filteredCameras.first.id, 'c4');

      controller.resetFilters();
      expect(controller.hasActiveFilters, isFalse);
      expect(controller.filteredCameras.length, 4);

      controller.setSearchQuery('tendean');
      expect(controller.filteredCameras.length, 1);
      expect(controller.filteredCameras.first.id, 'c3');
    });

    test('auto-scans on stream error and stops after manual selection', () {
      expect(controller.activeCamera?.id, 'c1');
      expect(controller.handleStreamError(), isTrue);
      expect(controller.activeCamera?.id, 'c2');

      // Manual selection disables auto-scan
      controller.selectCamera(controller.cameras[2]);
      expect(controller.activeCamera?.id, 'c3');
      expect(controller.handleStreamError(), isFalse);
    });
  });
}
