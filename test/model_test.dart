import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:uuid/uuid.dart';

void main() {
  void expectH(
  String actual,
  String matcher, {
  String reason,
  dynamic skip, // true or a String
}) => expect(actual.replaceAll(RegExp(r'#\S{36}$'), '').trim(), matcher,reason: reason, skip: skip);

  group('cronjob', () {
    test('gives correct time back', () {
      final timeIn = TimeOfDay(hour: 1, minute: 1);
      final daysIn = Set<Day>.from([Day.fri]);
      final job = CronJob(command: 'ls', time: timeIn, days: daysIn);
      
      expectH(job.toString(), '1 1 * * fri ls');
      expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
    });

    test('gives 24h time back', () {
      final timeIn = TimeOfDay(hour: 23, minute: 59);
      final daysIn = Set<Day>.from([Day.fri]);
      final job = CronJob(command: '', time: timeIn, days: daysIn);
      

      expectH(job.toString(), '59 23 * * fri');
      expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
    });

    test('gives 24h time back', () {
      final timeIn = TimeOfDay(hour: 23, minute: 59);
      final daysIn = Set<Day>.from([Day.fri]);
      final job = CronJob(command: '', time: timeIn, days: daysIn);

      expectH(job.toString(), '59 23 * * fri');
      expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
    });

    test('throws when minute is 59', () => expect(() => CronJob(command: 'ls', time: TimeOfDay(hour: 23, minute: 60), days: Set<Day>.from([Day.fri])), throwsAssertionError));
    test('throws when hour is over 23', () => expect(() => CronJob(command: 'ls', time: TimeOfDay(hour: 24, minute: 0), days: Set<Day>.from([Day.fri])), throwsAssertionError));
    test('throws when command is null', () => expect(() => CronJob(command: null, time: TimeOfDay(hour: 23, minute: 0), days: Set<Day>.from([Day.fri])), throwsAssertionError));

    test('sets correct day', () {
      final timeIn = TimeOfDay(hour: 23, minute: 59);
      final daysIn = Set<Day>.from([Day.thu]);
      final job = CronJob(command: '', time: timeIn, days: daysIn);

      expectH(job.toString(), '59 23 * * thu');
      expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
    });

    test('all correct days', () {
      final timeIn = TimeOfDay(hour: 10, minute: 00);
      final daysIn = Set<Day>.from([Day.mon, Day.tue, Day.wed, Day.thu, Day.fri, Day.sat, Day.sun,]);
      final job = CronJob(command: '', time: timeIn, days: daysIn);

      expectH(job.toString(), '0 10 * * mon,tue,wed,thu,fri,sat,sun');
    });

    test('does not repeat days', () {
      final timeIn = TimeOfDay(hour: 12, minute: 13);
      final daysIn = Set<Day>.from([Day.mon, Day.mon, Day.sun]);
      final job = CronJob(command: 'pwd', time: timeIn, days: daysIn);

      expectH(job.toString(), '13 12 * * mon,sun pwd');
       expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
    });

    test('correct time back', () {
      final timeIn = TimeOfDay(hour: 12, minute: 34);
      final daysIn = Set<Day>.from([Day.mon, Day.wed, Day.sun]);
      final job = CronJob(command: 'pwd', time: timeIn, days: daysIn);

      expectH(job.toString(), '34 12 * * mon,wed,sun pwd');
       expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
    });

    test('everyday constructor returns all days', () {
      final timeIn = TimeOfDay(hour: 15, minute: 45);
      final job = CronJob.everyday(command: 'ls', time: timeIn);

      expectH(job.toString(), '45 15 * * mon,tue,wed,thu,fri,sat,sun ls');
      expect(job.days, Day.values.toSet());
      expect(job.time, timeIn);
    });

    test('long command', () {
      final timeIn = TimeOfDay(hour: 12, minute: 34);
      final daysIn = Set<Day>.from([Day.mon, Day.wed, Day.sun]);
      final command = 'pwd aabs test liong command -s';
      final job = CronJob(command: command, time: timeIn, days: daysIn);

      expectH(job.toString(), '34 12 * * mon,wed,sun ' + command);
      expect(job.days, daysIn.toSet());
      expect(job.time, timeIn);
      expect(job.command, command);
    });

    test('parsing string', () {
      final uuid = Uuid().v1();
      var raw = '12 14 * * mon,fri,sun pwd some thing else #$uuid';
      final job = CronJob.parse(raw);
      expect(job.toString(), raw);
      expect(job.days, [Day.mon,Day.fri,Day.sun].toSet());
      expect(job.time, TimeOfDay(hour: 14, minute: 12));
      expect(job.command, 'pwd some thing else');
      expect(job.uuid, uuid);
    });
  });
}
