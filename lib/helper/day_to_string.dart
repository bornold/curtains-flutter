import 'dart:collection';

import 'package:curtains/models/alarms.dart';

String capitalize(String s) {
  var splitted = s.split('');
  splitted.first = splitted.first.toUpperCase();
  return splitted.join();
}

const weekdays = {Day.mon, Day.tue, Day.wed, Day.thu, Day.fri};
const weekends = {Day.sat, Day.sun};

extension on Day {
  String get name => toString().split('.').last;
}

String daysToSentence(Set<Day> days) {
  if (days.isEmpty) return 'once';
  if (days == Day.values.toSet()) return 'everyday';
  if (days.containsAll(weekdays) && days.length == weekdays.length) {
    return 'weekdays';
  }
  if (days.containsAll(weekends) && days.length == weekends.length) {
    return 'weekends';
  }

  return _longestDayChain(days);
}

String _longestDayChain(Set<Day> dayChain) {
  int nextDay(d) => (d + 1) % Day.values.length;
  int dayToIndex(d) => Day.values.indexOf(d);
  int dist(int d1Index, int d2Index) {
    return (d1Index > d2Index)
        ? Day.values.length - d1Index + d2Index + 1
        : d2Index - d1Index + 1;
  }

  Day firstDay = _findFirstDay(dayChain);
  int firstDayIndex = dayToIndex(firstDay);
  int lastDayIndex = firstDayIndex;
  int currentFirstDayIndex = firstDayIndex;

  var entities = <String>[];

  for (int i = nextDay(firstDayIndex); i != firstDayIndex; i = nextDay(i)) {
    if (dayChain.contains(Day.values[i])) {
      if (currentFirstDayIndex < 0) currentFirstDayIndex = i;
      lastDayIndex = i;
    } else if (currentFirstDayIndex > -1) {
      final d1 = Day.values[currentFirstDayIndex].fullName;
      final d2 = Day.values[lastDayIndex].fullName;

      int containingDays = dist(currentFirstDayIndex, lastDayIndex);

      if (containingDays < 2) {
        entities.add(d1);
      } else if (containingDays > 2) {
        entities.add('$d1 to $d2');
      } else {
        entities.addAll([d1, d2]);
      }
      currentFirstDayIndex = lastDayIndex = -1;
    }
  }

  if (currentFirstDayIndex > -1) {
    entities.add(Day.values[currentFirstDayIndex].fullName);
  }

  if (entities.length > 1) {
    final last = entities.removeLast();
    return '${entities.join(', ')} and $last';
  } else {
    return entities.first;
  }
}

Day _findFirstDay(Set<Day> dayChain) {
  if (dayChain.contains(Day.mon)) {
    var firstDay = Day.mon;
    for (final d in Day.values.reversed) {
      if (dayChain.contains(d)) {
        firstDay = d;
      } else if (firstDay == Day.sun && !dayChain.contains(Day.tue)) {
        return Day.mon;
      } else {
        return firstDay;
      }
    }
  } else {
    for (final d in Day.values) {
      if (dayChain.contains(d)) return d;
    }
  }
  return Day.mon;
}

String daysToString(Iterable<Day> days) => days.isEmpty
    ? ''
    : SplayTreeSet<Day>.from(days,
            (a, b) => Day.values.indexOf(a).compareTo(Day.values.indexOf(b)))
        .map((day) => day.name)
        .join(',');
