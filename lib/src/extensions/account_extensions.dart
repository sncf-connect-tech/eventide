import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_platform_interface.dart';

extension AccountToETAccount on Account {
  ETAccount toETAccount() {
    return ETAccount(
      name: name,
      type: type,
    );
  }
}

extension ETAccountToAccount on ETAccount {
  Account toAccount() {
    return Account(
      name: name,
      type: type,
    );
  }
}
