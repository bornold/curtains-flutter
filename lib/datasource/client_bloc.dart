import 'dart:async';
import 'dart:collection';

import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ClientProvider extends InheritedWidget {
  final ClientBloc client;

  ClientProvider({this.client, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(ClientProvider oldWidget) => true;

  static ClientProvider of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(ClientProvider);
}

enum SshState {
  disconnected,
  connecting,
  connected
}

abstract class ClientBloc {
  Stream<List<CronJob>> get alarms;
  Stream<SshState> get connection;
  Sink<CronJob> get alarmSink;
  Future refresh({bool forceRefresh = false});
  void updateItem(CronJob oldAlarm, CronJob newAlarm);
  void dispose();
  void disconnect();
  void connect();
} 

class MockedClientBloc implements ClientBloc {
  Stream<List<CronJob>> get alarms => _alarmsSubject.stream;
  final _alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();

  Stream<SshState> get connection => _connectionSubject.stream;
  final _connectionSubject = BehaviorSubject<SshState>();

  Sink<CronJob> get alarmSink => _alarmChangeController.sink;
  final _alarmChangeController = StreamController<CronJob>();

  var _alarms = <CronJob>[];

  MockedClientBloc() {
    _alarmChangeController.stream.listen(_onData);
    refresh();
  }

  Future refresh({bool forceRefresh = false}) async {
    if (forceRefresh || _alarms == null || _alarms.isEmpty) {
      _alarms = _generateJobs;
      await Future.delayed(Duration(seconds: 3));
      _connectionSubject.add(SshState.connecting);
      await Future.delayed(Duration(seconds: 2));
      _connectionSubject.add(SshState.connected);
      _update();
    }
  }

  _update() => _alarmsSubject.add(UnmodifiableListView(_alarms));

  void updateItem(CronJob oldAlarm, CronJob newAlarm) {
    _alarms[_alarms.indexOf(oldAlarm)] = newAlarm;
    _update();
  }

  Future open() => Future.delayed(Duration(seconds: 4), () {});


  void connect() {
    _connectionSubject.add(SshState.connected);
  }
  
  void disconnect() {
    _connectionSubject.add(SshState.disconnected);
  }

  void _onData(CronJob event) {
    if (!_alarms.remove(event)) {
      _alarms.add(event);
    }
    _update();
  }

  void dispose() {
    _alarmChangeController.close();
    _connectionSubject.close();
  }

  List<CronJob> get _generateJobs => [
      new CronJob(
          command: 'ls',
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
          command: 'ls',
          time: TimeOfDay(hour: 7, minute: 30),
          days: [Day.mon, Day.sat].toSet()),
      new CronJob(
          command: 'ls',
          time: TimeOfDay(hour: 8, minute: 41),
          days: [Day.mon].toSet()),
      new CronJob(
          command: 'ls',
          time: TimeOfDay(hour: 8, minute: 41),
          days: [Day.mon].toSet()),
      new CronJob(
          command: 'ls',
          time: TimeOfDay(hour: 8, minute: 42),
          days: [Day.mon].toSet()),
      new CronJob(
          command: 'ls',
          time: TimeOfDay(hour: 8, minute: 43),
          days: [Day.mon, Day.wed, Day.fri, Day.sun].toSet()),
    ];
}
