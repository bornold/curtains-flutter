import 'package:curtains/models/alarms.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class AtJob extends Alarm {
  final String command;
  final DateTime date;
  final int jobNr;

  static final dateFormat = DateFormat("EEE MMM d H:m:s");
  static final justTimeFormat = DateFormat("HH:mm");

  AtJob({
    required this.date,
    this.command = openCommand,
    required this.jobNr,
  }) : super(
          id: '$jobNr',
          days: const {},
          time: TimeOfDay.fromDateTime(date),
        );

  AtJob.createNew(DateTime date)
      : this(date: date, command: openCommand, jobNr: -1);

  static AtJob? parse(String raw) {
    final splitted = raw.split(RegExp(r'\s+'));
    final numberPart = splitted.removeAt(0);
    final jobNr = int.tryParse(numberPart);
    if (jobNr == null) return null;
    final datePart = splitted.sublist(0, 4).join(' ');

    final date = dateFormat.tryParse(datePart);
    if (date == null) return null;

    return AtJob(jobNr: jobNr, date: date, command: openCommand);
  }

  @override
  String toString() => raw;
  String get raw => 'echo "$command" | at ${justTimeFormat.format(date)}';

  @override
  List<Object?> get props => [command, time];

  @override
  bool? get stringify => true;
}
