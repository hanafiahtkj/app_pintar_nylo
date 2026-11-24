import '/app/events/login_success_event.dart';
import '/app/events/logout_event.dart';
import '/app/events/notification_refresh_event.dart';
import 'package:nylo_framework/nylo_framework.dart';

final Map<Type, NyEvent> events = {
  LogoutEvent: LogoutEvent(),
  LoginSuccessEvent: LoginSuccessEvent(),
  NotificationRefreshEvent: NotificationRefreshEvent(),
};
