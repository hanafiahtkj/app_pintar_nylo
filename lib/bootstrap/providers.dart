import '/app/providers/app_provider.dart';
import '/app/providers/deep_link_provider.dart';
import '/app/providers/event_provider.dart';
import '/app/providers/firebase_messaging_provider.dart';
import '/app/providers/in_app_update_provider.dart';
import '/app/providers/route_provider.dart';
import 'package:nylo_framework/nylo_framework.dart';

final Map<Type, NyProvider> providers = {
  AppProvider: AppProvider(),
  RouteProvider: RouteProvider(),
  EventProvider: EventProvider(),
  FirebaseMessagingProvider: FirebaseMessagingProvider(),
  DeepLinkProvider: DeepLinkProvider(),
  InAppUpdateProvider: InAppUpdateProvider(),
};
