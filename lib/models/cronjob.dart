import 'dart:collection';

import 'package:curtains/constants.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CronJob implements Comparable<CronJob> {
  
  final String command;
  final TimeOfDay time;
  final UnmodifiableListView<Day> days;
  String get uuid => _uuid;
  String _uuid;

  CronJob({@required this.time, @required Set<Day> days, this.command = open_command, String uuid})
  : _uuid = uuid ?? Uuid().v4(),
    days = UnmodifiableListView<Day>(days),
    assert(command != null),
    assert(time.hour < 24),
    assert(time.minute < 60),
    assert(days != null);
  
  CronJob.everyday({@required TimeOfDay time}) : this(time: time, days: Day.values.toSet());
  CronJob.clone({@required CronJob from, TimeOfDay newTime,  Set<Day> newDays, String newCommand}) 
  : this(
      time: newTime ?? TimeOfDay(hour: from.time.hour, minute: from.time.minute),
      days: newDays ?? from.days.toSet(), 
      command: newCommand ?? from.command, 
      uuid: from.uuid);
     
  factory CronJob.parse(String raw) {
    Day _parseDay(String dayStr) => Day.values.firstWhere((e) => e.toString() == 'Day.$dayStr', orElse: null);
    int uuidPart = raw.lastIndexOf('#');
    String uuid;
    if (uuidPart > 0) {
      uuid = raw.substring(uuidPart + 1, raw.length);
      raw = raw.substring(0, uuidPart);
    }
    var splitted = raw.trim().split(' ');
    int min = int.tryParse(splitted.removeAt(0)) ?? 0;
    int hour = int.tryParse(splitted.removeAt(0)) ?? 0;
    splitted.removeRange(0, 2);
    final dayPart = splitted.removeAt(0);
    final days = dayPart == '*' ? Set<Day>.identity() 
        : dayPart
            .split(',')
            .map(_parseDay)
            .toSet();
   
    final command = splitted.join(' ');
    final time = TimeOfDay(hour: hour, minute: min);
    return CronJob( days: days, time: time, command: command, uuid: uuid);
  }

  @override
  String toString() => raw;
  String get raw => "${time.minute} ${time.hour} * * ${days.isEmpty ? '*' : _daysToCronDays(days)} $command #$uuid".trim();

  @override
  int compareTo(CronJob other) {
    int hourComp = other.time.hour.compareTo(time.hour);
    return hourComp == 0 ? other.time.minute.compareTo(time.minute) : hourComp;
  }

  String _daysToCronDays(UnmodifiableListView<Day> days) => days.isEmpty ? '' :
     SplayTreeSet.from(days, (a,b) => Day.values.indexOf(a).compareTo(Day.values.indexOf(b))).map((day) => _dayToCronString(day)).join(',');
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
