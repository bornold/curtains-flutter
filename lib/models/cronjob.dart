import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum Day {
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun,
}
String enumName(Object o) => capitalize(o.toString().split('.').last);
String capitalize(String s) 
{
  var splitted = s.split('');
  splitted[0] = splitted.first.toUpperCase();
  return splitted.join();
}

class CronJob {
  String get raw => "${time.minute} ${time.hour} * * ${_daysToCronDays(Set.from(days.isEmpty ? Day.values : days))} $command".trim();
  String command;
  TimeOfDay time;
  Set<Day> days;
  String uuid = Uuid().v1();
  
  CronJob({this.command = '', @required this.time, @required this.days}) 
  : assert(time.hour < 24),
    assert(time.minute < 60),
    assert(command != null),
    assert(days != null);
    
  CronJob.everyday({command = '', @required time}) : this(command: command,time: time, days: Day.values.toSet());


  CronJob.parse(String raw) {
    Day _parseDay(String dayStr) => Day.values.firstWhere((e) => e.toString() == 'Day.$dayStr');
    var splitted = raw.split(' ');
    int min = int.tryParse(splitted.removeAt(0)) ?? 0;
    int hour = int.tryParse(splitted.removeAt(0)) ?? 0;
    this.time = TimeOfDay(hour: hour, minute: min);
    splitted.removeRange(0, 2);
    this.days = splitted
      .removeAt(0)
      .split(',')
      .map(_parseDay)
      .toSet();
    this.command = splitted.join(' ');
  }
    
  @override
  String toString({bool appendUUID = false}) => appendUUID ? '$raw $uuid' : raw;

  String _daysToCronDays(Set<Day> days) => days.isEmpty ? '' : days.map((day) => _dayToString(day)).join(',');
  String _dayToString(Day day) {
    switch (day) {
      case Day.mon: 
        return 'mon';
      case Day.tue: 
        return 'tue';
      case Day.wed: 
        return 'wed';
      case Day.thu: 
        return 'thu';
      case Day.fri: 
        return 'fri';
      case Day.sat: 
        return 'sat';
      case Day.sun: 
        return 'sun';
      default:
        return '';
    }
  }
}
