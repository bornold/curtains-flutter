import 'dart:async';

import 'package:curtains/datasource/connection.dart';
import 'package:curtains/datasource/repositories/assets.dart';
import 'package:curtains/datasource/repositories/preferenses.dart';
import 'package:curtains/models/alarms.dart';
import 'package:curtains/models/atjob.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/pages/connection_page.dart';

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

  Future<void> connect(final SSHConnectionInfo connectionInfo) async {
    try {
      emit(CurtainsConnecting());
      _connection = SSHConnection(connectionInfo);
      await _connection?.connect();
      return await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> checkConnection() async {
    final connectionInfo = await getConnectionInfo();
    if (connectionInfo == null) return disconnect();
    await connect(connectionInfo);
  }

  Future<SSHConnectionInfo?> getConnectionInfo() async {
    final preferences = Preferences(await SharedPreferences.getInstance());
    if (!preferences.autoconnect) return null;

    final ip = preferences.ip;
    final port = preferences.port;
    final passphrase = preferences.passphrase;
    final username = preferences.username;
    if (ip.isEmpty || passphrase.isEmpty || username.isEmpty) return null;

    final sshkey = await Assets(assetBundle).sshkey;
    return SSHConnectionInfo(
      user: username,
      host: ip,
      port: port,
      privatekey: sshkey,
      passphrase: passphrase,
    );
  }

  Future<void> disconnect() async {
    try {
      await _connection?.disconnect();
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
    final s = state;
    if (s is! CurtainsConnected) return;
    try {
      emit(CurtainsBusy(s.cronJobs, s.atJobs));
      await executeAndReconnectOnFail(() => _connection?.execute(openCommand));
      emit(CurtainsConnected(s.cronJobs, s.atJobs));
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future addAtJob(TimeOfDay time) async {
    final now = DateTime.now();
    DateTime dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final atJob = AtJob.createNew(dateTime);
    final command = atJob.toString();
    try {
      await executeAndReconnectOnFail(() => _connection?.execute(command));
      return await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future _addCronJob(CronJob cronJob) async {
    try {
      final add = '(crontab -l ; echo "$cronJob") | crontab -';
      debugPrint(add);
      await executeAndReconnectOnFail(() => _connection?.execute(add));
      return await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future removeAlarm(final Alarm alarm) async {
    try {
      if (alarm is CronJob) await _removeCronJob(alarm);
      if (alarm is AtJob) await _removeAtJob(alarm);
      await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future _removeCronJob(CronJob cronJob) async {
    final alarmEscaped = RegExp.escape(cronJob.toString());
    final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
    debugPrint(remove);
    await executeAndReconnectOnFail(() => _connection?.execute(remove));
  }

  Future _removeAtJob(AtJob at) async {
    final remove = "atrm ${at.jobNr}";
    debugPrint(remove);
    await executeAndReconnectOnFail(() => _connection?.execute(remove));
  }

  Future<void> updateTime(final Alarm alarm, TimeOfDay time) async {
    final s = state;
    if (s is! CurtainsConnected) return;
    if (alarm is CronJob) {
      final newCronJob = CronJob.clone(from: alarm, newTime: time);
      return _updateCronJob(newCronJob);
    }
    if (alarm is AtJob) {
      await _removeAtJob(alarm);
      await addAtJob(alarm.time);
    }
  }

  Future<void> updateDay(Alarm oldAlarm, Day day) async {
    var days = oldAlarm.days.toSet();
    if (!days.remove(day)) days.add(day);
    if (oldAlarm is CronJob) {
      if (days.isEmpty) {
        await _removeCronJob(oldAlarm);
        await addAtJob(oldAlarm.time);
        await _refresh();
        return;
      }
      await _updateCronJob(CronJob.clone(from: oldAlarm, newDays: days));
      await _refresh();
      return;
    }
    if (oldAlarm is AtJob) {
      await _removeAtJob(oldAlarm);
      final cronJob = CronJob(
        time: oldAlarm.time,
        days: days,
      );
      await _addCronJob(cronJob);
      await _refresh();
      return;
    }
  }

  Future<void> _updateCronJob(CronJob cronJob) async {
    final s = state;
    if (s is! CurtainsConnected) return;
    try {
      final uuidEscaped = RegExp.escape(cronJob.id);
      final updateCommand =
          "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$cronJob\") | crontab -";
      debugPrint(updateCommand);
      await executeAndReconnectOnFail(
          () => _connection?.execute(updateCommand));
      return await _refresh();
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> _refresh() async {
    notCommentOrWhitspace(String line) =>
        !line.startsWith('#') && line.trim().isNotEmpty;
    debugPrint('fetching cronjobs');
    final String? cronJobsRaw = await executeAndReconnectOnFail(
        () => _connection?.execute("crontab -l"));
    debugPrint('cronjobs result: $cronJobsRaw');
    if (cronJobsRaw == null) return disconnect();
    final cronJobs = cronJobsRaw
        .split(RegExp(r'[\n\r]'))
        .where(notCommentOrWhitspace)
        .map(CronJob.parse)
        .whereNotNull()
        .toList();

    final String? atJobsRaw =
        await executeAndReconnectOnFail(() => _connection?.execute("at -l"));

    final atJobs = atJobsRaw
            ?.split(RegExp(r'[\n\r]'))
            .map(AtJob.parse)
            .whereNotNull()
            .toList() ??
        <AtJob>[];
    emit(CurtainsConnected(cronJobs, atJobs));
  }

  Future<T> executeAndReconnectOnFail<T>(
    FutureOr<T> Function() f, {
    int depth = 0,
  }) async {
    try {
      return await f();
    } on PlatformException catch (pe) {
      if (depth > 3) rethrow;
      if (pe.message == ConnectionSettings.errorSessionDown) rethrow;
      debugPrint("session is down, trying to reconnect");
      await _connection?.disconnect();
      await _connection?.connect().timeout(const Duration(seconds: 4));
      debugPrint("reconnect connect successfull, executing statment again");
      return executeAndReconnectOnFail(f, depth: depth + 1);
    }
  }
}
