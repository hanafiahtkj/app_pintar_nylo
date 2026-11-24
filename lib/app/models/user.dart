import 'package:nylo_framework/nylo_framework.dart';

class User extends Model {
  int? id;
  String? name;
  String? email;
  String? employeeIdNumber;
  String? nationalIdNumber;
  String? whatsAppNumber;
  String? type;
  int? isPolling;
  String? token;

  static final StorageKey key = 'user';

  User({
    this.id,
    this.name,
    this.email,
    this.employeeIdNumber,
    this.nationalIdNumber,
    this.whatsAppNumber,
    this.type,
    this.isPolling,
    this.token,
  }) : super(key: key);

  User.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = data['id'];
      name = data['name'];
      email = data['email'];
      employeeIdNumber = data['employeeIdNumber'];
      nationalIdNumber = data['nationalIdNumber'];
      whatsAppNumber = data['whatsAppNumber'];
      type = data['type'];
      isPolling = data['is_polling'];
      token = data['token'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'employeeIdNumber': employeeIdNumber,
        'nationalIdNumber': nationalIdNumber,
        'whatsAppNumber': whatsAppNumber,
        'type': type,
        'is_polling': isPolling,
        'token': token,
      };
}
