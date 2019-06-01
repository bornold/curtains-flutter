
import 'dart:async';
import 'dart:collection';

import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class MockedClientBloc extends ClientBloc {

  Stream<List<CronJob>> get alarms => alarmsSubject.stream;
  Stream<SshState> get connection => connectionSubject.stream;
  Stream<CronJob> get updatedAlarms => updateAlarmsSubject.stream; 
  Sink<CronJob> get alarmSink => alarmsSetChangeController.sink;
  Sink<ConnectionEvents> get connectionEvents => connectionController.sink;
  Sink<CronJob> get updateAlarmSink => updateAlarmsSubject.sink;

  final alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();
  final updateAlarmsSubject = PublishSubject<CronJob>();
  final connectionSubject = BehaviorSubject<SshState>();
  final connectionController = StreamController<ConnectionEvents>();
  final alarmsSetChangeController = StreamController<CronJob>();
  
  var _alarms = <CronJob>[];

  MockedClientBloc() {
    connectionController.stream.listen(_onConnectionRequest);
    alarmsSetChangeController.stream.listen(_onNewAlarm);
  }
    
  void dispose() {
    alarmsSetChangeController.close();
    connectionSubject.close();
    connectionController.close();
    updateAlarmsSubject.close();
    alarmsSubject.close();
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
        connectionSubject.add(SshState.connecting);
        await Future.delayed(Duration(seconds: 2));
        refresh();
        connectionSubject.add(SshState.connected);
        break;
      case ConnectionEvents.disconnect:
          connectionSubject.add(SshState.disconnected);
        break;
      case ConnectionEvents.open:
          connectionSubject.add(SshState.busy);
          await Future.delayed(Duration(seconds: 2));
          connectionSubject.add(SshState.connected);
        break;
      case ConnectionEvents.refresh:
        connectionSubject.add(SshState.busy);
        await Future.delayed(Duration(seconds: 1));
        await refresh();
        connectionSubject.add(SshState.connected);
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
    alarmsSubject.add(UnmodifiableListView(_alarms));
  }
} 
