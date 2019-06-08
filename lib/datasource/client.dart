import 'dart:async';
import 'dart:collection';

import 'package:curtains/constants.dart';
import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:curtains/models/cronjob.dart';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ssh/ssh.dart';


class Client extends ClientBloc {
  final _alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();
  final _connectionSubject = BehaviorSubject<ConnectionStatus>()..add(ConnectionStatus.disconnected);
  final _availablitySubject = BehaviorSubject<Availability>()..add(Availability.idle);
  final _updateAlarmsSubject = StreamController<CronJob>.broadcast();
  final _connectionController = StreamController<ConnectionEvent>();
  final _alarmsSetChangeController = StreamController<CronJob>();
  final _connectionInfoController = StreamController<ConnectionInfo>();

  Stream<List<CronJob>> get alarms => _alarmsSubject.stream;
  Stream<CronJob> get updatedAlarms => _updateAlarmsSubject.stream;
  Stream<ConnectionStatus> get connection => _connectionSubject.stream;
  Stream<Availability> get availability => _availablitySubject.stream;
  Sink<CronJob> get alarmSink => _alarmsSetChangeController.sink;
  Sink<CronJob> get updateAlarmSink => _updateAlarmsSubject.sink;
  Sink<ConnectionEvent> get connectionEvents => _connectionController.sink;
  Sink<ConnectionInfo> get connectionInfoSink => _connectionInfoController.sink;

  final String connectionOk = "session_connected";
  var _alarms = <CronJob>[];
  SSHClient _client;

  Client() {
    _connectionController.stream.listen(handelConnectionRequest);
    _alarmsSetChangeController.stream.listen(handelNewAlarm);
    _updateAlarmsSubject.stream.listen(handelAlarmUpdate);
    _connectionInfoController.stream.listen(handelClientInfo);
  }

  void dispose() {
    _alarmsSubject.close();
    _alarmsSetChangeController.close();
    _connectionSubject.close();
    _connectionController.close();
    _updateAlarmsSubject.close();
    _connectionInfoController.close();
    _availablitySubject.close();
    _client.disconnect();
  }

  void handelConnectionRequest(ConnectionEvent event) async {
  Future refresh() async {
    _connectionSubject.add(ConnectionStatus.loadning);

    final notCommentOrWhitspace =
        (String line) => !line.startsWith('#') && line.trim().isNotEmpty;
    debugPrint('fetching cronjobs');
    final String res = await _client.execute("crontab -l");
    debugPrint('cronjobs result: $res');
    final alarms = res
        .split(RegExp(r'[\n?\r]'))
        .where(notCommentOrWhitspace)
        .map((cronjob) => CronJob.parse(cronjob))
        .toList();
    alarms.forEach((c) => debugPrint(c.toString()));
    _alarms = alarms;
    _update();

    _connectionSubject.add(ConnectionStatus.connected);
  }

    debugPrint(event.toString());
    if (_client == null) {
      debugPrint('_client not set');
      _connectionSubject.addError(Exception('must set connection info first'));
      return;
    }
    try {
      switch (event) {

        case ConnectionEvent.connect:
          _connectionSubject.add(ConnectionStatus.connecting);
          final connectionResult = await _client.connect().timeout(Duration(seconds: 4));
          if (connectionResult != connectionOk) {
            _connectionSubject.addError(Exception(connectionResult));
            return;
          }
          debugPrint('connection success');
          await refresh();
          break;

        case ConnectionEvent.disconnect:
          _client?.disconnect();
          _connectionSubject.add(ConnectionStatus.disconnected);
          break;

        case ConnectionEvent.open:
          _availablitySubject.add(Availability.busy);
          await _client.execute(open_command);
          _availablitySubject.add(Availability.idle);
          break;

        case ConnectionEvent.refresh:
          await refresh();
          break;

      }
    } catch (e) {
      debugPrint(e.toString());
      _connectionSubject.addError(e);
    }
  }

  void handelNewAlarm(CronJob event) async {
    if (_alarms.remove(event)) {
      _update();
      final alarmEscaped = RegExp.escape(event.toString());
      final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
      debugPrint(remove);
      debugPrint(await _client.execute(remove));
    } else {
      _alarms.add(event);
      _update();
      final add = '(crontab -l ; echo "$event") | crontab -';
      debugPrint(add);
      debugPrint(await _client.execute(add));
    }
  }

  void handelAlarmUpdate(CronJob newAlarm) async {
    _alarms
      ..removeWhere((c) => c.uuid == newAlarm.uuid)
      ..add(newAlarm);
    _update();
    final uuidEscaped = RegExp.escape(newAlarm.uuid);
    final update =
        "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$newAlarm\") | crontab -";
    debugPrint(update);
    debugPrint(await _client.execute(update));
  }

  void handelClientInfo(ConnectionInfo conInfo) {
    if (_client == null) {
      _client = SSHClient(
          username: conInfo.user,
          host: conInfo.host,
          port: conInfo.port,
          passwordOrKey: {
            "privateKey": conInfo.privatekey,
            "passphrase": conInfo.passphrase,
          });
      _client.stateSubscription.onData(handleStateChange);
    } else {
      _client.username = conInfo.user;
      _client.host = conInfo.host;
      _client.port = conInfo.port;
      _client.passwordOrKey = {
        "privateKey": conInfo.privatekey,
        "passphrase": conInfo.passphrase,
      };
    }
  }

  void handleStateChange(data) {
    debugPrint(data.toString());
  }

  _update() {
    debugPrint('updating with alarms views');
    _alarms.sort((a1, a2) => a2.compareTo(a1));
    _alarmsSubject.add(UnmodifiableListView(_alarms));
  }
}
