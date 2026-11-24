import 'package:nylo_framework/nylo_framework.dart';

class NotificationRefreshEvent implements NyEvent {
  @override
  final listeners = {
    DefaultListener: DefaultListener(),
  };
}

class DefaultListener extends NyListener {
  @override
  handle(dynamic data) async {
    // HomePage and NotificationListWidget react via broadcastEvents listeners
    // (avoiding duplicate updateState + listen double-fetching).
  }
}
