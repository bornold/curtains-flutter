import 'dart:async';
import 'dart:convert';

import 'package:curtains/models/connection_info.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

abstract class Connection {
  Future<String?> execute(String cmd);
  Future<void> connect();
  FutureOr<void> disconnect();
}

class SSHConnection implements Connection {
  final SSHConnectionInfo connectionInfo;
  SSHConnection(this.connectionInfo);

  late SSHClient _sshClient;

  @override
  Future<void> connect() async {
    _sshClient = SSHClient(
      await SSHSocket.connect(connectionInfo.host, connectionInfo.port),
      username: connectionInfo.user,
      identities: [
        ...SSHKeyPair.fromPem(
          connectionInfo.privatekey,
          connectionInfo.passphrase,
        )
      ],
      printDebug: debugPrint,
      printTrace: debugPrint,
    );
    await _sshClient.authenticated;
  }

  @override
  Future<void> disconnect() async {
    _sshClient.close();
    await _sshClient.done;
  }

  @override
  Future<String?> execute(String cmd) async =>
      utf8.decode(await _sshClient.run(cmd));
}
