import 'dart:async';
import 'dart:convert';

import 'package:curtains/models/connection_info.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

class SSHConnection {
  final SSHConnectionInfo connectionInfo;
  SSHConnection(this.connectionInfo);

  late SSHClient _sshClient;

  Future<void> connect() async {
    try {
      debugPrint('Connecting');
      _sshClient = SSHClient(
        await SSHSocket.connect(connectionInfo.host, connectionInfo.port),
        username: connectionInfo.user,
        identities: SSHKeyPair.fromPem(
          connectionInfo.privatekey,
          connectionInfo.passphrase,
        ),
        printDebug: debugPrint,
        printTrace: debugPrint,
      );
      await _sshClient.authenticated;
    } catch (e) {
      debugPrint('Error connecting');
      debugPrint(e.toString());
    }
  }

  Future<void> disconnect() async {
    try {
      debugPrint('Disconnecting');
      _sshClient.close();
      await _sshClient.done;
    } catch (e) {
      debugPrint('Error disconnecting');
      debugPrint(e.toString());
    }
  }

  Future<String?> execute(String cmd) async =>
      utf8.decode(await _sshClient.run(cmd));
}
