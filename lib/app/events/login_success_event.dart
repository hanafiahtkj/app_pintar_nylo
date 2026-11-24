import 'package:nylo_framework/nylo_framework.dart';

class LoginSuccessEvent implements NyEvent {
  @override
  final listeners = {
    DefaultListener: DefaultListener(),
  };
}

class DefaultListener extends NyListener {
  @override
  handle(dynamic data) async {
    // Handled via broadcastEvents listeners (HomePage, ProfileBodyWidget, LoginPage)
  }
}
