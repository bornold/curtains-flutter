import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CronJob implements Comparable<CronJob> {
  String command;
  TimeOfDay time;
  Set<Day> days;
  String uuid = Uuid().v1();
  CronJob({this.command = 'open', @required this.time, @required this.days}) 
  : assert(time.hour < 24),
    assert(time.minute < 60),
    assert(command != null),
    assert(days != null);
  
  CronJob.everyday({command = '', @required time}) : this(command: command,time: time, days: Day.values.toSet());
     
  CronJob.parse(String raw) {
    Day _parseDay(String dayStr) => 
    Day.values.firstWhere((e) => e.toString() == 'Day.$dayStr');
    var splitted = raw.split(' ');
    int min = int.tryParse(splitted.removeAt(0)) ?? 0;
    int hour = int.tryParse(splitted.removeAt(0)) ?? 0;
    this.time = TimeOfDay(hour: hour, minute: min);
    splitted.removeRange(0, 2);
    final dayPart = splitted.removeAt(0);
    this.days = dayPart == '*' ? Set<Day>.identity() 
        : dayPart
            .split(',')
            .map(_parseDay)
            .toSet();
    this.uuid = splitted.removeLast().split('#').last;
    this.command = splitted.join(' ');
  }

  String get raw => "${time.minute} ${time.hour} * * ${days.isEmpty ? '*' : _daysToCronDays(days)} $command #$uuid".trim();
 
  @override
  int compareTo(CronJob other) {
    int hourComp = other.time.hour.compareTo(time.hour);
    return hourComp == 0 ? other.time.minute.compareTo(time.minute) : hourComp;
  }

  @override
  String toString() => raw;

  String _daysToCronDays(Set<Day> days) => days.isEmpty ? '' : days.map((day) => _dayToCronString(day)).join(',');
  String _dayToCronString(Day day) {
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

enum Day {
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun,
}
