import '../helper/day_to_string.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CronJob implements Comparable<CronJob> {
  static const openCommand = '~/bin/open';
  final String command;
  final TimeOfDay time;
  final UnmodifiableListView<Day> days;
  String get uuid => _uuid;
  String _uuid;

  CronJob({
    required this.time,
    required Set<Day> days,
    this.command = openCommand,
    String? uuid,
  })  : _uuid = uuid ?? const Uuid().v4(),
        days = UnmodifiableListView<Day>(days),
        assert(time.hour < 24),
        assert(time.minute < 60);

  CronJob.everyday({required TimeOfDay time})
      : this(time: time, days: Day.values.toSet());
  CronJob.clone({
    required CronJob from,
    TimeOfDay? newTime,
    Set<Day>? newDays,
    String? newCommand,
  }) : this(
          time: newTime ??
              TimeOfDay(hour: from.time.hour, minute: from.time.minute),
          days: newDays ?? from.days.toSet(),
          command: newCommand ?? from.command,
          uuid: from.uuid,
        );

  static CronJob? parse(String raw) {
    Day? _parseDay(String dayStr) =>
        Day.values.firstWhereOrNull((e) => e.toString() == 'Day.$dayStr');
    int uuidPart = raw.lastIndexOf('#');
    String uuid;
    if (uuidPart <= 0) return null;

    uuid = raw.substring(uuidPart + 1, raw.length);
    raw = raw.substring(0, uuidPart);

    var splitted = raw.trim().split(' ');
    int min = int.tryParse(splitted.removeAt(0)) ?? 0;
    int hour = int.tryParse(splitted.removeAt(0)) ?? 0;
    splitted.removeRange(0, 2);
    final dayPart = splitted.removeAt(0);
    final days = dayPart == '*'
        ? Set<Day>.identity()
        : dayPart.split(',').map(_parseDay).whereNotNull().toSet();

    final command = splitted.join(' ');
    final time = TimeOfDay(hour: hour, minute: min);
    return CronJob(days: days, time: time, command: command, uuid: uuid);
  }

  @override
  String toString() => raw;
  String get raw =>
      "${time.minute} ${time.hour} * * ${days.isEmpty ? '*' : daysToString(days)} $command #$uuid"
          .trim();

  @override
  int compareTo(CronJob other) {
    int hourComp = other.time.hour.compareTo(time.hour);
    return hourComp == 0 ? other.time.minute.compareTo(time.minute) : hourComp;
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
