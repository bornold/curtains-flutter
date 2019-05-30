import 'dart:async';
import 'dart:collection';

import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ClientBloc {
  final _alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();
  final _updateAlarmsSubject = PublishSubject<CronJob>();

  final _connectionSubject = BehaviorSubject<SshState>();
  final _connectionController = StreamController<ConnectionEvents>();

  final _alarmsSetChangeController = StreamController<CronJob>();
  Stream<List<CronJob>> get alarms => _alarmsSubject.stream;

  Sink<CronJob> get alarmSink => _alarmsSetChangeController.sink;
  Stream<SshState> get connection => _connectionSubject.stream;

  Sink<ConnectionEvents> get connectionEvents => _connectionController.sink;
  Sink<CronJob> get updateAlarmSink => _updateAlarmsSubject.sink;

  Stream<CronJob> get updatedAlarms => _updateAlarmsSubject.stream; 

  void dispose() {
    _alarmsSetChangeController.close();
    _connectionSubject.close();
    _connectionController.close();
    _updateAlarmsSubject.close();
  }
}

class ClientProvider extends InheritedWidget {
  final ClientBloc client;

  ClientProvider({this.client, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(ClientProvider oldWidget) => true;

  static ClientProvider of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(ClientProvider);
}

enum ConnectionEvents {
  connect,
  disconnect,
  refresh,
  open
}

class MockedClientBloc extends ClientBloc {
  var _alarms = <CronJob>[];

  MockedClientBloc() {
    _connectionController.stream.listen(_onConnectionRequest);
    _alarmsSetChangeController.stream.listen(_onNewAlarm);
  }
    
  List<CronJob> get _generateJobs => [
    new CronJob(
        time: TimeOfDay(hour: 6, minute: 30),
        days: [
          Day.mon,
          Day.tue,
          Day.wed,
          Day.thu,
          Day.fri,
          Day.sat,
          Day.sun
        ].toSet()),
    new CronJob(
        time: TimeOfDay(hour: 7, minute: 30),
        days: [Day.mon, Day.sat].toSet()),
    new CronJob(
        time: TimeOfDay(hour: 8, minute: 41),
        days: [Day.mon].toSet()),
    new CronJob(
        time: TimeOfDay(hour: 8, minute: 41),
        days: [Day.mon].toSet()),
    new CronJob(
        time: TimeOfDay(hour: 8, minute: 42),
        days: [Day.mon].toSet()),
    new CronJob(
        time: TimeOfDay(hour: 8, minute: 43),
        days: [Day.mon, Day.wed, Day.fri, Day.sun].toSet()),
  ];
 
  Future refresh() async {
    if (_alarms == null || _alarms.isEmpty) {
      _alarms = _generateJobs;
    }
    _update();
  }
  
  void _onConnectionRequest(ConnectionEvents event) async {
    switch (event) {
      case ConnectionEvents.connect:
        _connectionSubject.add(SshState.connecting);
        await Future.delayed(Duration(seconds: 2));
        refresh();
        _connectionSubject.add(SshState.connected);
        break;
      case ConnectionEvents.disconnect:
          _connectionSubject.add(SshState.disconnected);
        break;
      case ConnectionEvents.open:
          _connectionSubject.add(SshState.busy);
          await Future.delayed(Duration(seconds: 2));
          _connectionSubject.add(SshState.connected);
        break;
      case ConnectionEvents.refresh:
        _connectionSubject.add(SshState.busy);
        await Future.delayed(Duration(seconds: 1));
        await refresh();
        _connectionSubject.add(SshState.connected);
        break;
      default:
    }
  }
    
  void _onNewAlarm(CronJob event) {
    if (!_alarms.remove(event)) {
      _alarms.add(event);
    }
    _update();
  }
    
  _update() {
    _alarms.sort((a1,a2) => a2.compareTo(a1));
    _alarmsSubject.add(UnmodifiableListView(_alarms));
  }
} 

enum SshState {
  disconnected,
  connecting,
  connected,
  busy
}
