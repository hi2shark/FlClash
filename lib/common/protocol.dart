import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

class Protocol {
  static Protocol? _instance;

  Protocol._internal();

  factory Protocol() {
    _instance ??= Protocol._internal();
    return _instance!;
  }

  void register(String scheme) {
    final String protocolRegKey = 'Software\\Classes\\$scheme';
    const String protocolCmdRegKey = 'shell\\open\\command';
    final regKey = CURRENT_USER.create(protocolRegKey);
    try {
      regKey.setValue('URL Protocol', const RegistryValue.string(''));
      final cmdKey = regKey.create(protocolCmdRegKey);
      try {
        cmdKey.setValue(
          '',
          RegistryValue.string('"${Platform.resolvedExecutable}" "%1"'),
        );
      } finally {
        cmdKey.close();
      }
    } finally {
      regKey.close();
    }
  }
}

final protocol = Protocol();
