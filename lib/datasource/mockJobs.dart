import 'dart:async';

import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';

class MockClient with ChangeNotifier 
{
  List<CronJob> _mockJobs;
  List<CronJob> get _generateJobs =>
  [
    new CronJob(command: 'ls', time: TimeOfDay(hour: 6, minute: 30), days: [Day.mon, Day.tue, Day.wed, Day.thu, Day.fri, Day.sat, Day.sun].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 7, minute: 30), days: [Day.mon, Day.sat].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 41), days: [Day.mon].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 41), days: [Day.mon].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 42), days: [Day.mon].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 43), days: [Day.mon, Day.wed, Day.fri , Day.sun].toSet()),
  ];



  Future<List<CronJob>> alarms({bool forceRefresh = false}) 
  {
      if (forceRefresh || _mockJobs == null || _mockJobs.isEmpty) {
        _mockJobs = _generateJobs;
        notifyListeners();
        return Future.delayed(Duration(seconds: 3), () => _mockJobs);
      }
      else  {
        var competer = Completer<List<CronJob>>();
        competer.complete(_mockJobs);
        return competer.future;
      }
  }

    void add(CronJob alarm) {
      _mockJobs.add(alarm);
      notifyListeners();
    }

    void remove(CronJob alarm) {
      _mockJobs.remove(alarm);
      notifyListeners();
    } 
      
    void updateItem(CronJob oldAlarm, CronJob newAlarm) {
        _mockJobs[_mockJobs.indexOf(oldAlarm)] = newAlarm;
        notifyListeners();
    } 

    Future open() =>
      Future.delayed(Duration(seconds: 4), () {});
}