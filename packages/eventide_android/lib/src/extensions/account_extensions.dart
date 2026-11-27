import 'package:eventide_platform_interface/eventide_platform_interface.dart';

import 'package:eventide_android/src/calendar_api.g.dart';

extension AccountToETAccount on Account {
  ETAccount toETAccount() {
    return ETAccount(id: id, name: name, type: type);
  }
}

extension AccountListToETAccount on List<Account> {
  List<ETAccount> toETAccountList() {
    return map((a) => a.toETAccount()).toList();
  }
}

extension ETAccountToAccount on ETAccount {
  Account toAccount() {
    return Account(id: id, name: name, type: type);
  }
}
