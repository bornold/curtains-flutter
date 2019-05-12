import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';

class MockClient with ChangeNotifier 
{
  List<CronJob> _mockJobs = 
  [
    new CronJob(command: 'ls', time: TimeOfDay(hour: 6, minute: 30), days: [Day.mon, Day.tue, Day.wed, Day.thu, Day.fri, Day.sat, Day.sun].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 7, minute: 30), days: [Day.mon, Day.sat].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 41), days: [Day.mon].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 42), days: [Day.mon].toSet()),
    new CronJob(command: 'ls', time: TimeOfDay(hour: 8, minute: 43), days: [Day.mon, Day.wed, Day.fri , Day.sun].toSet()),
  ];

  Future<List<CronJob>> get alarms =>
    Future.delayed(Duration(seconds: 3), () => _mockJobs);

  List<CronJob> get alarmsNow =>_mockJobs;

    Future add(CronJob alarm) => 
      Future.delayed(Duration(seconds: 1), () {
      _mockJobs.add(alarm);
      notifyListeners();
      });

    Future<bool> delete(CronJob alarm) => 
      Future.delayed(Duration(seconds: 1), () {
        _mockJobs.remove(alarm);
        notifyListeners();
      });
      
      Future<bool> updateItem(CronJob oldAlarm, CronJob newAlarm) => 
        Future.delayed(Duration(seconds: 1), () {
          _mockJobs.remove(oldAlarm);
          _mockJobs.add(newAlarm);
          notifyListeners();
        });

    Future open() =>
      Future.delayed(Duration(seconds: 4), () {});
}