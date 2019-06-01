library days_string_tests;

import 'package:curtains/helper/dayToString.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curtains/models/cronjob.dart';

void main() {
  final timeIn = TimeOfDay(hour: 1, minute: 1);
  CronJob newjob(daysIn) => CronJob(time: timeIn, days: daysIn);

  group('days to string tests', () {
    test('no days no string', () {
      final job = newjob(Set<Day>.identity());
      expect(daysToString(job.days), '');
    });
    test('Day.mon in monday', () {
      final job = newjob([Day.mon].toSet());
      expect(daysToString(job.days), 'monday');
    });
    test('Day.sat in saturday', () {
      final job = newjob([Day.sat].toSet());
      expect(daysToString(job.days), 'saturday');
    });
    test('Everyday is everyday', () {
      final job = CronJob.everyday(time: timeIn);
      expect(daysToString(job.days), 'everyday');
    });
    test('Day.mon, Day.tue is monday and tuesday', () {
      final job = newjob([Day.mon, Day.tue].toSet());
      expect(daysToString(job.days), 'monday and tuesday');
    });
    test('Day.mon, Day.tue, Day.thu is monday, tuesday and thursday', () {
      final job = newjob([Day.mon, Day.tue, Day.thu].toSet());
      expect(daysToString(job.days), 'monday, tuesday and thursday');
    });

    test('Day.mon, Day.tue, Day.thu, Day.fri is monday, tuesday, thursday, and friday', () {
      final job = newjob([Day.mon, Day.tue, Day.thu, Day.fri].toSet());
      expect(daysToString(job.days), 'monday, tuesday, thursday and friday');
    });

    test('Day.tue, Day.wed, Day.fri, Day.sun is tuesday, wednesday, friday and sunday', () {
      final job = newjob([Day.tue, Day.wed, Day.fri, Day.sun].toSet());
      expect(daysToString(job.days), 'tuesday, wednesday, friday and sunday');
    });

    test('Day order does not matter', () {
      final job = newjob([Day.fri, Day.wed, Day.sun, Day.tue].toSet());
      expect(daysToString(job.days), 'tuesday, wednesday, friday and sunday');
    });

    test('Day.mon, Day.tue, Day.wed, is monday to wednesday', () {
      final job = newjob([Day.mon, Day.tue, Day.wed].toSet());
      expect(daysToString(job.days), 'monday to wednesday');
    });

    test('Day.mon, Day.tue, Day.wed, Day.fri, Day.sat, is monday to wednesday and friday', () {
      final job = newjob([Day.mon, Day.tue, Day.wed, Day.fri].toSet());
      expect(daysToString(job.days), 'monday to wednesday and friday');
    });

    test('Day.mon, Day.tue, Day.wed, Day.fri, Day.sat, is monday to wednesday, friday and saturday', () {
      final job = newjob([Day.mon, Day.tue, Day.wed, Day.fri, Day.sat].toSet());
      expect(daysToString(job.days), 'monday to wednesday, friday and saturday');
    });

    test('Day.mon, Day.sat, Day.wed, Day.fri, Day.tue, is monday to wednesday, friday and saturday', () {
      final job = newjob([Day.mon, Day.sat, Day.wed, Day.fri, Day.tue].toSet());
      expect(daysToString(job.days), 'monday to wednesday, friday and saturday');
    });

    test('Day.mon, Day.tue, Day.wed, Day.sun, is sunday to wednesday', () {
      final job = newjob([Day.mon, Day.tue, Day.wed, Day.sun].toSet());
      expect(daysToString(job.days), 'sunday to wednesday');
    });

    test('Day.mon, Day.sun, Day.sat, Day.fri, Day.thu, Day.wed is wednesday to monday', () {
      final job = newjob([Day.mon, Day.sun, Day.sat, Day.fri, Day.thu, Day.wed].toSet());
      expect(daysToString(job.days), 'wednesday to monday');
    });

    test('Day.sun, Day.sat, Day.fri, Day.thu, Day.wed, is wednesday to sunday', () {
      final job = newjob([Day.sun, Day.sat, Day.fri, Day.thu, Day.wed,].toSet());
      expect(daysToString(job.days), 'wednesday to sunday');
    });

    test('Day.mon Day.wed, Day.thu, Day.fri, Day.sat is monday and wednesday to saturday', () {
      final job = newjob([Day.mon,  Day.wed, Day.thu, Day.fri, Day.sat,].toSet());
      expect(daysToString(job.days), 'monday and wednesday to saturday');
    });

    test('Day.mon, Day.tue, Day.thu, Day.fri, Day.sat is monday, tuesday and wednesday to saturday', () {
      final job = newjob([Day.mon, Day.tue, Day.thu, Day.fri, Day.sat].toSet());
      expect(daysToString(job.days), 'monday, tuesday and thursday to saturday');
    });

    test('Day.sun, Day.mon, Day.wed, is monday, wednesday to friday and sunday', () {
      final job = newjob([Day.sun, Day.mon, Day.wed,].toSet());
      expect(daysToString(job.days), 'monday, wednesday and sunday');
    });

    test('Day.mon, Day.wed, Day.thu, Day.fri, Day.sun is monday, wednesday to friday and sunday', () {
      final job = newjob([Day.mon, Day.wed, Day.thu, Day.fri, Day.sun].toSet());
      expect(daysToString(job.days), 'monday, wednesday to friday and sunday');
    });
  });
}