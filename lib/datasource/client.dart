import 'dart:async';
import 'dart:collection';

import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/sensitive.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ssh/ssh.dart';

class Client extends ClientBloc {

  final _alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();
  final _connectionSubject = BehaviorSubject<SshState>();
  final _updateAlarmsSubject = PublishSubject<CronJob>();
  final _connectionController = PublishSubject<ConnectionEvents>();
  final _alarmsSetChangeController = PublishSubject<CronJob>();
  
  Stream<List<CronJob>> get alarms => _alarmsSubject.stream;
  Stream<CronJob> get updatedAlarms => _updateAlarmsSubject.stream; 
  Stream<SshState> get connection => _connectionSubject.stream;
  Sink<CronJob> get alarmSink => _alarmsSetChangeController.sink;
  Sink<ConnectionEvents> get connectionEvents => _connectionController.sink;
  Sink<CronJob> get updateAlarmSink => _updateAlarmsSubject.sink;

  final String connectionOk = "session_connected";

  var _alarms = <CronJob>[];

  SSHClient _client;
  Client() {
    _client = SSHClient(
      host: "192.168.1.227",
      port: 22,
      username: "pi",
      passwordOrKey: {
        "privateKey": privateKey,
        "passphrase": passphrase,
      });
    _connectionController.stream.listen(_onConnectionRequest);
    _alarmsSetChangeController.stream.listen(_onNewAlarm);
    _updateAlarmsSubject.stream.listen(_onAlarmUpdate);
  }

  void dispose() {
    _alarmsSubject.close();
    _alarmsSetChangeController.close();
    _connectionSubject.close();
    _connectionController.close();
    _updateAlarmsSubject.close();
    _client.disconnect();
  }

  void _onConnectionRequest(ConnectionEvents event) async {
    try
    {
      switch (event) {

        case ConnectionEvents.connect:
          debugPrint('connect event');
          _connectionSubject.add(SshState.connecting);
          if (await _client.connect() == connectionOk) _connectionSubject.add(SshState.connected);
          else {
            _connectionSubject.add(SshState.disconnected);
            return;
          }
          debugPrint('connection success');
          _connectionSubject.add(SshState.busy);
          await refresh();
          _connectionSubject.add(SshState.connected);
          break;

        case ConnectionEvents.disconnect:
          _client.disconnect();
          _connectionSubject.add(SshState.disconnected);
          break;

        case ConnectionEvents.open:
          _connectionSubject.add(SshState.busy);
          await _client.execute(open_command);
          _connectionSubject.add(SshState.connected);        
          break;

        case ConnectionEvents.refresh:
          _connectionSubject.add(SshState.busy);
          await refresh();
          _connectionSubject.add(SshState.connected);
          break;
      }
    }
    catch (e) {
      debugPrint(e);
      _connectionSubject.addError(e);
    }
  }

  Future refresh() async {
    final notCommentOrWhitspace = (String line) => !line.startsWith('#') && line.trim().isNotEmpty;
    final String res = await _client.execute("crontab -l");
    final alarms = res
        .split(RegExp(r'[\n?\r]'))
        .where(notCommentOrWhitspace)
        .map((cronjob) => CronJob.parse(cronjob))
        .toList();
    _alarms = alarms;
    _update();
  }

  void _onNewAlarm(CronJob event) async {
    if (_alarms.remove(event)) {
      _update();
      final alarmEscaped = RegExp.escape(event.toString());
      final remove = "crontab -l | grep -v '^$alarmEscaped\$' | crontab -";
      debugPrint(remove);
      debugPrint(await _client.execute(remove));
    }
    else {
      _alarms.add(event);
      _update();
      final add = '(crontab -l ; echo "$event") | crontab -';
      debugPrint(add);
      debugPrint(await _client.execute(add));
    }
  }

  _update() {
    _alarms.sort((a1, a2) => a2.compareTo(a1));
    _alarmsSubject.add(UnmodifiableListView(_alarms));
  }

  void _onAlarmUpdate(CronJob newAlarm) async {
    _alarms
      ..removeWhere((c) => c.uuid == newAlarm.uuid)
      ..add(newAlarm);
    _update();
    final uuidEscaped = RegExp.escape(newAlarm.uuid);
    final update = "(crontab -l | grep -v '#$uuidEscaped\$' ; echo \"$newAlarm\") | crontab -";
    debugPrint(update);
    debugPrint(await _client.execute(update));
  }
}
