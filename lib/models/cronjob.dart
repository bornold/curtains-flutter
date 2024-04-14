import 'package:curtains/models/alarms.dart';

import '../helper/day_to_string.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const openCommand = '~/bin/open';

class CronJob extends Alarm {
  final String command;

  CronJob({
    required super.time,
    required super.days,
    this.command = openCommand,
    String? id,
  })  : assert(time.hour < 24),
        assert(time.minute < 60),
        super(id: id ?? const Uuid().v4());

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
          id: from.id,
        );

  static CronJob? parse(String raw) {
    Day? parseDay(String dayStr) =>
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
        : dayPart.split(',').map(parseDay).whereNotNull().toSet();

    final command = splitted.join(' ');
    final time = TimeOfDay(hour: hour, minute: min);
    return CronJob(days: days, time: time, command: command, id: uuid);
  }

  @override
  String toString() => raw;
  String get raw =>
      "${time.minute} ${time.hour} * * ${days.isEmpty ? '*' : daysToString(days)} $command #$id"
          .trim();

  @override
  List<Object?> get props => [command, time, days];
}
