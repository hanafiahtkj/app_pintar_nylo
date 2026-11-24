import '/app/controllers/home_controller.dart';
import '/app/models/banner_item.dart';
import '/app/models/category_item.dart';
import '/app/models/emergency_category.dart';
import '/app/models/emergency_item.dart';
import '/app/models/hotline.dart';
import '/app/models/layanan_app.dart';
import '/app/models/lowongan.dart';
import '/app/models/notification_item.dart';
import '/app/models/notification_page_response.dart';
import '/app/models/polling.dart';
import '/app/models/post.dart';
import '/app/models/urgent_notification.dart';
import '/app/models/user.dart';
import '/app/networking/karier_api_service.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/native_service_registry.dart';

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['data'] is List) {
    return data['data'] as List<dynamic>;
  }
  return <dynamic>[];
}

final Map<Type, dynamic> modelDecoders = {
  User: (data) => User.fromJson(data),
  List<User>: (data) =>
      _extractList(data).map((json) => User.fromJson(json)).toList(),
  LayananApp: (data) => LayananApp.fromJson(data),
  List<LayananApp>: (data) =>
      _extractList(data).map((json) => LayananApp.fromJson(json)).toList(),
  BannerItem: (data) => BannerItem.fromJson(data),
  List<BannerItem>: (data) =>
      _extractList(data).map((json) => BannerItem.fromJson(json)).toList(),
  Hotline: (data) => Hotline.fromJson(data),
  Polling: (data) => Polling.fromJson(data),
  CategoryItem: (data) => CategoryItem.fromJson(data),
  List<CategoryItem>: (data) =>
      _extractList(data).map((json) => CategoryItem.fromJson(json)).toList(),
  EmergencyItem: (data) => EmergencyItem.fromJson(data),
  List<EmergencyItem>: (data) =>
      _extractList(data).map((json) => EmergencyItem.fromJson(json)).toList(),
  EmergencyCategory: (data) => EmergencyCategory.fromJson(data),
  List<EmergencyCategory>: (data) => _extractList(data)
      .map((json) => EmergencyCategory.fromJson(json))
      .toList(),
  Lowongan: (data) => Lowongan.fromJson(data),
  List<Lowongan>: (data) =>
      _extractList(data).map((json) => Lowongan.fromJson(json)).toList(),
  Post: (data) => Post.fromJson(data),
  List<Post>: (data) =>
      _extractList(data).map((json) => Post.fromJson(json)).toList(),
  UrgentNotification: (data) => UrgentNotification.fromJson(data),
  List<UrgentNotification>: (data) => _extractList(data)
      .map((json) => UrgentNotification.fromJson(json))
      .toList(),
  NotificationItem: (data) => NotificationItem.fromJson(data),
  List<NotificationItem>: (data) => _extractList(data)
      .map((json) => NotificationItem.fromJson(json))
      .toList(),
  NotificationPageResponse: (data) => NotificationPageResponse.fromJson(data),
  ...NativeServiceRegistry().allModelDecoders,
};

final Map<Type, dynamic> apiDecoders = {
  PintarApiService: () => PintarApiService(),
  KarierApiService: () => KarierApiService(),
  ...NativeServiceRegistry().allApiDecoders,
};

final Map<Type, dynamic> controllers = {
  HomeController: () => HomeController(),
  ...NativeServiceRegistry().allControllers,
};
