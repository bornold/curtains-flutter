import 'dart:async';
import 'dart:collection';

import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ClientProvider extends InheritedWidget {
  final ClientBloc client;

  ClientProvider({this.client, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static ClientProvider of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(ClientProvider);
}

class ClientBloc {
  Stream<List<CronJob>> get alarms => _alarmsSubject.stream;
  final _alarmsSubject = BehaviorSubject<UnmodifiableListView<CronJob>>();

  Sink<CronJob> get addition => _additionController.sink;
  final _additionController = StreamController<CronJob>();

  Sink<CronJob> get subraction => _subractionController.sink;
  final _subractionController = StreamController<CronJob>();

  var _alarms = <CronJob>[];

  ClientBloc() {
    _additionController.stream.listen(onDataAdd);
    _subractionController.stream.listen(onDataRemove);
    refresh();
  }

  Future refresh({bool forceRefresh = false}) async {
    if (forceRefresh || _alarms == null || _alarms.isEmpty) {
      _alarms = _generateJobs;
      await Future.delayed(Duration(seconds: 6), () => _alarms);
      _update();
    }
  }

  _update() => _alarmsSubject.add(UnmodifiableListView(_alarms));

  void updateItem(CronJob oldAlarm, CronJob newAlarm) {
    _alarms[_alarms.indexOf(oldAlarm)] = newAlarm;
    _update();
  }

  Future open() => Future.delayed(Duration(seconds: 4), () {});

  void onDataAdd(CronJob event) {
    _alarms.add(event);
    _update();
  }

  void onDataRemove(CronJob event) {
    _alarms.remove(event);
    _update();
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
