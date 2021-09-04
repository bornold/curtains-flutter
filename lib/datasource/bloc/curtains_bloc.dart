import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../../constants.dart';
import '../connection.dart';

part 'curtains_event.dart';
part 'curtains_state.dart';

class CurtainsBloc extends Bloc<CurtainsEvent, CurtainsState> {
  CurtainsBloc() : super(CurtainsConnecting());
  Connection _connection;

  @override
  Stream<CurtainsState> mapEventToState(
    CurtainsEvent event,
  ) async* {
    try {
      if (event is ConnectEvent) {
        yield CurtainsConnecting();
        final connectionInfo = event.connectionInfo;
        if (connectionInfo is SSHConnectionInfo) {
          _connection = SSHConnection(connectionInfo);
        } else if (connectionInfo is RestfullConnectionInfo) {
          _connection = RestfullConnection(connectionInfo);
        }
        await _connection.connect();
        yield* _refresh();
      }

      if (event is Disconnect) {
        _connection?.disconnect();
        yield CurtainsDisconnected();
      }

      if (event is RefreshEvent) {
        yield* _refresh();
      }

      final oldState = state;
      if (oldState is CurtainsConnected) {
        final alarms = oldState.alarms.toList();
        if (event is AddOrRemoveCroneJob) {
          yield* _handleAddOrRemoveAlarm(event.cronJob, alarms);
        }

        if (event is UpdateCroneJob) {
          yield* _handelAlarmUpdate(event.cronJob, alarms);
        }

        if (event is OpenEvent) {
          yield CurtainsBusy(alarms);
          await executeAndReconnectOnFail(
              () => _connection.execute(open_command));
          yield CurtainsConnected(alarms);
        }
      }
    } catch (e) {
      debugPrint(e.toString());

      yield CurtainsDisconnected(e);
    }
  }

  Stream<CurtainsState> _handleAddOrRemoveAlarm(
      CronJob event, List<CronJob> alarms) async* {
    if (alarms.remove(event)) {
      yield CurtainsConnected(alarms);

      final alarmEscaped = RegExp.escape(event.toString());
      final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
      debugPrint(remove);
      await executeAndReconnectOnFail(() => _connection.execute(remove));
    } else {
      alarms.add(event);
      yield CurtainsConnected(alarms);

      final add = '(crontab -l ; echo "$event") | crontab -';
      debugPrint(add);
      await executeAndReconnectOnFail(() => _connection.execute(add));
    }
  }

  Stream<CurtainsState> _handelAlarmUpdate(
      CronJob newAlarm, List<CronJob> alarms) async* {
    alarms
      ..removeWhere((c) => c.uuid == newAlarm.uuid)
      ..add(newAlarm);
    yield CurtainsConnected(alarms);
    final uuidEscaped = RegExp.escape(newAlarm.uuid);
    final updateCommand =
        "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$newAlarm\") | crontab -";
    debugPrint(updateCommand);
    await executeAndReconnectOnFail(() => _connection.execute(updateCommand));
  }

  Stream<CurtainsState> _refresh() async* {
    final notCommentOrWhitspace =
        (String line) => !line.startsWith('#') && line.trim().isNotEmpty;
    debugPrint('fetching cronjobs');
    final String res = await executeAndReconnectOnFail(
        () => _connection.execute("crontab -l"));
    debugPrint('cronjobs result: $res');
    final cronJobs = res
        .split(RegExp(r'[\n?\r]'))
        .where(notCommentOrWhitspace)
        .map((cronjob) => CronJob.parse(cronjob))
        .toList();
    cronJobs.forEach((c) => debugPrint(c.toString()));
    yield CurtainsConnected(cronJobs);
  }

  Future executeAndReconnectOnFail(Function f, {int depth = 0}) async {
    try {
      return await f();
    } on PlatformException catch (pe) {
      if (pe.message == errorSessionDown && depth < 3) {
        debugPrint("session is down, trying to reconnect");
        _connection.disconnect();
        await _connection.connect().timeout(Duration(seconds: 4));
        debugPrint("reconnect connect successfull, executing statment again");
        return executeAndReconnectOnFail(f, depth: depth + 1);
      } else
        throw pe;
    }
  }
}
