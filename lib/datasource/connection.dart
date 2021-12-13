import 'dart:io';

import 'package:curtains/models/connection_info.dart';
import 'package:flutter/foundation.dart';
import 'package:ssh2/ssh2.dart';

import '../constants.dart';

abstract class Connection {
  Future<String?> execute(String cmd);
  Future<String?> connect();
  disconnect();
}

class SSHConnection implements Connection {
  SSHConnection(SSHConnectionInfo connectionInfo) {
    _sshClient = SSHClient(
        username: connectionInfo.user,
        host: connectionInfo.host,
        port: connectionInfo.port,
        passwordOrKey: {
          "privateKey": connectionInfo.privatekey,
          "passphrase": connectionInfo.passphrase,
        });
    _sshClient.stateSubscription.onData((d) => debugPrint(d.toString()));
  }

  late SSHClient _sshClient;

  void handelConnectionInfoChanged(SSHConnectionInfo connectionInfo) {
    _sshClient.username = connectionInfo.user;
    _sshClient.host = connectionInfo.host;
    _sshClient.port = connectionInfo.port;
    _sshClient.passwordOrKey = {
      "privateKey": connectionInfo.privatekey,
      "passphrase": connectionInfo.passphrase,
    };
  }

  @override
  Future<String?> connect() => _sshClient.connect();

  @override
  disconnect() => _sshClient.disconnect();

  @override
  Future<String?> execute(String cmd) => _sshClient.execute(cmd);
}

class RestfullConnection implements Connection {
  RestfullConnection(RestfullConnectionInfo connectionInfo);
  @override
  Future<String> connect() => Future.value(connectionOk);

  @override
  disconnect() {}

  @override
  Future<String> execute(String cmd) async {
    final result = await Process.run(cmd, [], runInShell: true);
    if (result.exitCode == 0) return result.stdout;
    return result.stderr;
  }
}
