import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum Day {
  mon('monday'),
  tue('tuesday'),
  wed('wednesday'),
  thu('thursday'),
  fri('friday'),
  sat('saturday'),
  sun('sunday');

  const Day(this.fullName);
  final String fullName;
}

abstract class Alarm extends Equatable implements Comparable<Alarm> {
  final String id;
  final TimeOfDay time;
  final Set<Day> days;

  const Alarm({
    required this.id,
    required this.time,
    required this.days,
  });

  @override
  int compareTo(Alarm other) {
    int hourComp = other.time.hour.compareTo(time.hour);
    return hourComp == 0 ? other.time.minute.compareTo(time.minute) : hourComp;
  }
}
