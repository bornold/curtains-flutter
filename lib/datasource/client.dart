import 'dart:async';
import 'dart:collection';

import 'package:curtains/datasource/connection.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/subjects.dart';

import '../constants.dart';
import '../datasource/client_bloc.dart';
import '../models/connection_info.dart';
import '../models/cronjob.dart';

import 'package:flutter/foundation.dart';

class Client extends ClientBloc {
  final alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();
  final connectionSubject = BehaviorSubject<ConnectionStatus>()
    ..add(ConnectionStatus.disconnected);
  final availablitySubject = BehaviorSubject<Availability>()
    ..add(Availability.idle);
  final updateAlarmsSubject = StreamController<CronJob>.broadcast();
  final connectionController = StreamController<ConnectionEvent>();
  final alarmsSetChangeController = StreamController<CronJob>();
  final connectionInfoController = StreamController<ConnectionInfo>();

  Stream<List<CronJob>> get alarmStream => alarmsSubject.stream;
  Stream<CronJob> get updatedAlarms => updateAlarmsSubject.stream;
  Stream<ConnectionStatus> get connectionStatus => connectionSubject.stream;
  Stream<Availability> get availability => availablitySubject.stream;
  Sink<CronJob> get alarmSink => alarmsSetChangeController.sink;
  Sink<CronJob> get updateAlarmSink => updateAlarmsSubject.sink;
  Sink<ConnectionEvent> get connectionEvents => connectionController.sink;
  Sink<ConnectionInfo> get connectionInfoSink => connectionInfoController.sink;

  var alarms = <CronJob>[];
  // SSHClient client;
  Connection connection;

  Client() {
    connectionController.stream.listen(handelConnectionRequest);
    alarmsSetChangeController.stream.listen(handelNewAlarm);
    updateAlarmsSubject.stream.listen(handelAlarmUpdate);
    connectionInfoController.stream.listen(handelClientInfo);
  }

  dispose() {
    alarmsSubject.close();
    alarmsSetChangeController.close();
    connectionSubject.close();
    connectionController.close();
    updateAlarmsSubject.close();
    connectionInfoController.close();
    availablitySubject.close();
    connection?.disconnect();
  }

  handelConnectionRequest(ConnectionEvent event) async {
    Future refresh() async {
      connectionSubject.add(ConnectionStatus.loadning);
      final notCommentOrWhitspace =
          (String line) => !line.startsWith('#') && line.trim().isNotEmpty;
      debugPrint('fetching cronjobs');
      final String res = await executeAndReconnectOnFail(
          () => connection.execute("crontab -l"));
      debugPrint('cronjobs result: $res');
      final cronJobs = res
          .split(RegExp(r'[\n?\r]'))
          .where(notCommentOrWhitspace)
          .map((cronjob) => CronJob.parse(cronjob))
          .toList();
      cronJobs.forEach((c) => debugPrint(c.toString()));
      alarms = cronJobs;
      update();

      connectionSubject.add(ConnectionStatus.connected);
    }

    debugPrint(event.toString());
    if (connection == null) {
      debugPrint('connection not set');
      connectionSubject.addError(Exception('must set connection info first'));
      return;
    }
    try {
      switch (event) {
        case ConnectionEvent.connect:
          connectionSubject.add(ConnectionStatus.connecting);
          final connectionResult =
              await connection.connect().timeout(Duration(seconds: 4));
          if (connectionResult != connectionOk) {
            connectionSubject.addError(Exception(connectionResult));
            return;
          }
          debugPrint('connection success');
          await refresh();
          break;

        case ConnectionEvent.disconnect:
          connection?.disconnect();
          connectionSubject.add(ConnectionStatus.disconnected);
          debugPrint('disconnected');
          break;

        case ConnectionEvent.open:
          availablitySubject.add(Availability.busy);
          await executeAndReconnectOnFail(
              () => connection.execute(open_command));
          availablitySubject.add(Availability.idle);
          break;

        case ConnectionEvent.refresh:
          await refresh();
          break;
      }
    } catch (e) {
      debugPrint(e.toString());
      connectionSubject.addError(e);
    }
  }

  handelNewAlarm(CronJob event) async {
    try {
      if (alarms.remove(event)) {
        update();
        final alarmEscaped = RegExp.escape(event.toString());
        final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
        debugPrint(remove);
        await executeAndReconnectOnFail(() => connection.execute(remove));
      } else {
        alarms.add(event);
        update();
        final add = '(crontab -l ; echo "$event") | crontab -';
        debugPrint(add);
        await executeAndReconnectOnFail(() => connection.execute(add));
      }
    } catch (e) {
      debugPrint(e.toString());
      connectionSubject.addError(e);
    }
  }

  handelAlarmUpdate(CronJob newAlarm) async {
    try {
      alarms
        ..removeWhere((c) => c.uuid == newAlarm.uuid)
        ..add(newAlarm);
      update();
      final uuidEscaped = RegExp.escape(newAlarm.uuid);
      final updateCommand =
          "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$newAlarm\") | crontab -";
      debugPrint(updateCommand);
      await executeAndReconnectOnFail(() => connection.execute(updateCommand));
    } catch (e) {
      debugPrint(e.toString());
      connectionSubject.addError(e);
    }
  }

  handelClientInfo(ConnectionInfo conInfo) {
    debugPrint("new connectionInfo $conInfo");
    if (connection != null) connection?.disconnect();
    if (conInfo is SSHConnectionInfo) {
      connection = SSHConnection(conInfo);
    }
    if (conInfo is LocalConnectionInfo) {
      connection = LocalConnection();
    }
  }

  handleStateChange(data) {
    debugPrint(data.toString());
  }

  update() {
    debugPrint('updating with alarms views');
    alarms.sort((a1, a2) => a2.compareTo(a1));
    alarmsSubject.add(UnmodifiableListView(alarms));
  }

  Future executeAndReconnectOnFail(Function f, {int depth = 0}) async {
    try {
      return await f();
    } on PlatformException catch (pe) {
      if (pe.message == errorSessionDown && depth < 3) {
        debugPrint("session is down, trying to reconnect");
        connection.disconnect();
        await connection.connect().timeout(Duration(seconds: 4));
        debugPrint("reconnect connect successfull, executing statment again");
        return executeAndReconnectOnFail(f, depth: depth + 1);
      } else
        throw pe;
    }
  }
}
