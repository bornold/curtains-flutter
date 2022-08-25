import 'dart:async';

import 'package:curtains/constants.dart';
import 'package:curtains/datasource/connection.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';




part 'curtains_state.dart';

class CurtainsCubit extends Cubit<CurtainsState> {
  CurtainsCubit({required this.assetBundle}) : super(CurtainsConnecting());

  Connection? _connection;
  final AssetBundle assetBundle;

  Future<void> connect(final ConnectionInfo connectionInfo) async {
    try {
      emit(CurtainsConnecting());

      if (connectionInfo is SSHConnectionInfo) {
        _connection = SSHConnection(connectionInfo);
      } else if (connectionInfo is RestfullConnectionInfo) {
        _connection = RestfullConnection(connectionInfo);
      }
      await _connection?.connect();
      return await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> checkConnection() async {
    final connectionInfo = await getConnectionInfo();
    if (connectionInfo != null) {
      connect(connectionInfo);
    } else {
      disconnect();
    }
  }

  Future<ConnectionInfo?> getConnectionInfo() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getBool(autoconnectPrefsKey) ?? false) {
      final ip = sharedPreferences.getString(adressPrefsKey);
      final port = sharedPreferences.getInt(portPrefsKey);
      final passphrase = sharedPreferences.getString(passphraseSercureKey);

      if (ip != null && port != null && passphrase != null) {
        final sshkey = await assetBundle.loadString(privateKeyPath);
        return SSHConnectionInfo(
            host: ip, port: port, privatekey: sshkey, passphrase: passphrase);
      }
    }
    return null;
  }

  Future<void> disconnect() async {
    try {
      _connection?.disconnect();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      emit(CurtainsDisconnected());
    }
  }

  Future<void> refresh() async {
    try {
      return await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected());
    }
  }

  Future<void> open() async {
    try {
      final s = state;
      if (s is CurtainsConnected) {
        final alarms = s.alarms.toList();
        emit(CurtainsBusy(alarms));
        await executeAndReconnectOnFail(
            () => _connection?.execute(openCommand));
        emit(CurtainsConnected(alarms));
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future addOrRemoveAlarm(final CronJob cronJob) async {
    try {
      final oldState = state;
      if (oldState is CurtainsConnected) {
        final alarms = oldState.alarms.toList();
        if (alarms.remove(cronJob)) {
          final alarmEscaped = RegExp.escape(cronJob.toString());
          final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
          debugPrint(remove);
          await executeAndReconnectOnFail(() => _connection?.execute(remove));
        } else {
          final add = '(crontab -l ; echo "$cronJob") | crontab -';
          debugPrint(add);
          await executeAndReconnectOnFail(() => _connection?.execute(add));
        }
        return await _refresh();
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> update(final CronJob cronJob) async {
    try {
      final s = state;
      if (s is CurtainsConnected) {
        final uuidEscaped = RegExp.escape(cronJob.uuid);
        final updateCommand =
            "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$cronJob\") | crontab -";
        debugPrint(updateCommand);
        await executeAndReconnectOnFail(
            () => _connection?.execute(updateCommand));
        return await _refresh();
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> _refresh() async {
    notCommentOrWhitspace(String line) =>
        !line.startsWith('#') && line.trim().isNotEmpty;
    debugPrint('fetching cronjobs');
    final String? res = await executeAndReconnectOnFail(
        () => _connection?.execute("crontab -l"));
    debugPrint('cronjobs result: $res');
    if (res == null) {
      return disconnect();
    }
    final cronJobs = res
        .split(RegExp(r'[\n?\r]'))
        .where(notCommentOrWhitspace)
        .map((cronjob) => CronJob.parse(cronjob))
        .whereNotNull()
        .toList();
    for (var c in cronJobs) {
      debugPrint(c.toString());
    }
    emit(CurtainsConnected(cronJobs));
  }

  Future<T> executeAndReconnectOnFail<T>(FutureOr<T> Function() f,
      {int depth = 0}) async {
    try {
      return await f();
    } on PlatformException catch (pe) {
      if (pe.message == errorSessionDown && depth < 3) {
        debugPrint("session is down, trying to reconnect");
        _connection?.disconnect();
        await _connection?.connect().timeout(const Duration(seconds: 4));
        debugPrint("reconnect connect successfull, executing statment again");
        return executeAndReconnectOnFail(f, depth: depth + 1);
      } else {
        rethrow;
      }
    }
  }
}
