import 'dart:async';
import 'dart:collection';

import 'package:rxdart/subjects.dart';

import '../datasource/client_bloc.dart';
import '../models/connection_info.dart';
import '../models/cronjob.dart';
import 'package:flutter/material.dart';

class MockedClient extends ClientBloc {
  Stream<List<CronJob>> get alarmStream => alarmsSubject.stream;
  Stream<ConnectionStatus> get connection => connectionSubject.stream;
  Stream<CronJob> get updatedAlarms => updateAlarmsSubject.stream;
  Stream<Availability> get availability => availablitySubject.stream;
  Sink<CronJob> get alarmSink => alarmsSetChangeController.sink;
  Sink<ConnectionEvent> get connectionEvents => connectionController.sink;
  Sink<CronJob> get updateAlarmSink => updateAlarmsSubject.sink;
  Sink<ConnectionInfo> get connectionInfoSink => connectionInfoController.sink;

  final alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();
  final updateAlarmsSubject = PublishSubject<CronJob>();
  final availablitySubject = BehaviorSubject<Availability>();
  final connectionSubject = BehaviorSubject<ConnectionStatus>();
  final connectionController = StreamController<ConnectionEvent>();
  final alarmsSetChangeController = StreamController<CronJob>();
  final connectionInfoController = StreamController<ConnectionInfo>();

  var _alarms = <CronJob>[];

  MockedClient() {
    connectionController.stream.listen(_onConnectionRequest);
    alarmsSetChangeController.stream.listen(_onNewAlarm);
  }

  void dispose() {
    alarmsSetChangeController.close();
    connectionSubject.close();
    connectionController.close();
    updateAlarmsSubject.close();
    alarmsSubject.close();
    connectionInfoController.close();
    availablitySubject.close();
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
            time: TimeOfDay(hour: 8, minute: 41), days: [Day.mon].toSet()),
        new CronJob(
            time: TimeOfDay(hour: 8, minute: 41), days: [Day.mon].toSet()),
        new CronJob(
            time: TimeOfDay(hour: 8, minute: 42), days: [Day.mon].toSet()),
        new CronJob(
            time: TimeOfDay(hour: 8, minute: 43),
            days: [Day.mon, Day.wed, Day.fri, Day.sun].toSet()),
      ];

  void refresh() async {
    if (_alarms == null || _alarms.isEmpty) {
      _alarms = _generateJobs;
    }
    _update();
  }

  void _onConnectionRequest(ConnectionEvent event) async {
    switch (event) {
      case ConnectionEvent.connect:
        connectionSubject.add(ConnectionStatus.connecting);
        await Future.delayed(Duration(seconds: 2));
        connectionSubject.add(ConnectionStatus.connected);
        connectionSubject.add(ConnectionStatus.loadning);
        refresh();
        connectionSubject.add(ConnectionStatus.connected);
        break;
      case ConnectionEvent.disconnect:
        connectionSubject.add(ConnectionStatus.disconnected);
        break;
      case ConnectionEvent.open:
        availablitySubject.add(Availability.busy);
        await Future.delayed(Duration(seconds: 2));
        availablitySubject.add(Availability.idle);
        break;
      case ConnectionEvent.refresh:
        connectionSubject.add(ConnectionStatus.loadning);
        await Future.delayed(Duration(seconds: 1));
        refresh();
        connectionSubject.add(ConnectionStatus.connected);
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
    _alarms.sort((a1, a2) => a2.compareTo(a1));
    alarmsSubject.add(UnmodifiableListView(_alarms));
  }
}
