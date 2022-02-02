import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

import '../../constants.dart';
import '../connection.dart';

part 'curtains_event.dart';
part 'curtains_state.dart';

class CurtainsBloc extends Bloc<CurtainsEvent, CurtainsState> {
  CurtainsBloc() : super(CurtainsConnecting()) {
    on<ConnectEvent>(_onConnectEvent);
    on<Disconnect>(_onDisconnect);
    on<RefreshEvent>(_onRefresh);
    on<UpdateCroneJob>(_handelAlarmUpdate);
    on<AddOrRemoveCroneJob>(_handleAddOrRemoveAlarm);
    on<OpenEvent>(_onOpen);
  }

  Connection? _connection;

  Future<void> _onConnectEvent(
    ConnectEvent event,
    Emitter<CurtainsState> emit,
  ) async {
    try {
      emit(CurtainsConnecting());
      final connectionInfo = event.connectionInfo;
      if (connectionInfo is SSHConnectionInfo) {
        _connection = SSHConnection(connectionInfo);
      } else if (connectionInfo is RestfullConnectionInfo) {
        _connection = RestfullConnection(connectionInfo);
      }
      await _connection?.connect();
      emit(await _refresh());
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> _onDisconnect(
    Disconnect event,
    Emitter<CurtainsState> emit,
  ) async {
    try {
      _connection?.disconnect();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      emit(CurtainsDisconnected());
    }
  }

  Future<void> _onRefresh(_, Emitter<CurtainsState> emit) async {
    try {
      emit(await _refresh());
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected());
    }
  }

  Future<void> _onOpen(OpenEvent event, Emitter<CurtainsState> emit) async {
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

  Future _handleAddOrRemoveAlarm(
    AddOrRemoveCroneJob event,
    Emitter<CurtainsState> emit,
  ) async {
    try {
      final oldState = state;
      if (oldState is CurtainsConnected) {
        final alarms = oldState.alarms.toList();
        final job = event.cronJob;
        if (alarms.remove(job)) {
          final alarmEscaped = RegExp.escape(event.toString());
          final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
          debugPrint(remove);
          await executeAndReconnectOnFail(() => _connection?.execute(remove));
        } else {
          final add = '(crontab -l ; echo "$event") | crontab -';
          debugPrint(add);
          await executeAndReconnectOnFail(() => _connection?.execute(add));
        }
        emit(await _refresh());
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<void> _handelAlarmUpdate(
      UpdateCroneJob event, Emitter<CurtainsState> emit) async {
    try {
      final s = state;
      if (s is CurtainsConnected) {
        final newAlarm = event.cronJob;
        final uuidEscaped = RegExp.escape(newAlarm.uuid);
        final updateCommand =
            "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$newAlarm\") | crontab -";
        debugPrint(updateCommand);
        await executeAndReconnectOnFail(
            () => _connection?.execute(updateCommand));
        emit(await _refresh());
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(CurtainsDisconnected(e));
    }
  }

  Future<CurtainsState> _refresh() async {
    notCommentOrWhitspace(String line) =>
        !line.startsWith('#') && line.trim().isNotEmpty;
    debugPrint('fetching cronjobs');
    final String res = await executeAndReconnectOnFail(
        () => _connection?.execute("crontab -l"));
    debugPrint('cronjobs result: $res');
    final cronJobs = res
        .split(RegExp(r'[\n?\r]'))
        .where(notCommentOrWhitspace)
        .map((cronjob) => CronJob.parse(cronjob))
        .whereNotNull()
        .toList();
    for (var c in cronJobs) {
      debugPrint(c.toString());
    }
    return CurtainsConnected(cronJobs);
  }

  Future executeAndReconnectOnFail(Function f, {int depth = 0}) async {
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
