import 'package:nylo_framework/nylo_framework.dart';

class LogoutEvent implements NyEvent {
  @override
  final listeners = {
    DefaultListener: DefaultListener(),
  };
}

class DefaultListener extends NyListener {
  @override
  handle(dynamic data) async {
    // Auth.logout() is already executed in AuthService.logout();
    // UI components react via broadcastEvents listeners.
  }
}
