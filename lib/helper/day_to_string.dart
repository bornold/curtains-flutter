import 'dart:collection';

import '../models/cronjob.dart';

String capitalize(String s) {
  var splitted = s.split('');
  splitted.first = splitted.first.toUpperCase();
  return splitted.join();
}

String daysToSentence(Iterable<Day> days) {
  String dayToString(Day day) {
    switch (day) {
      case Day.mon:
        return 'monday';
      case Day.tue:
        return 'tuesday';
      case Day.wed:
        return 'wednesday';
      case Day.thu:
        return 'thursday';
      case Day.fri:
        return 'friday';
      case Day.sat:
        return 'saturday';
      case Day.sun:
        return 'sunday';
      default:
        return '';
    }
  }

  Day findFirstDay(Iterable<Day> dayChain) {
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

  nextDay(d) => (d + 1) % Day.values.length;
  dayToIndex(d) => Day.values.indexOf(d);
  indexToDay(i) => Day.values[i];
  int dist(int d1Index, int d2Index) {
    return (d1Index > d2Index)
        ? Day.values.length - d1Index + d2Index + 1
        : d2Index - d1Index + 1;
  }

  String longestDayChain(Iterable<Day> dayChain) {
    Day firstDay = findFirstDay(dayChain);
    int firstDayIndex = dayToIndex(firstDay);
    int lastDayIndex = firstDayIndex;
    int currentFirstDayIndex = firstDayIndex;

    var entities = <String>[];

    for (int i = nextDay(firstDayIndex); i != firstDayIndex; i = nextDay(i)) {
      if (dayChain.contains(indexToDay(i))) {
        if (currentFirstDayIndex < 0) currentFirstDayIndex = i;
        lastDayIndex = i;
      } else if (currentFirstDayIndex > -1) {
        final d1 = dayToString(indexToDay(currentFirstDayIndex));
        final d2 = dayToString(indexToDay(lastDayIndex));

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
      entities.add(dayToString(indexToDay(currentFirstDayIndex)));
    }

    if (entities.length > 1) {
      final last = entities.removeLast();
      return '${entities.join(', ')} and $last';
    } else {
      return entities.first;
    }
  }

  if (days.isEmpty) return '';
  if (days.toSet().containsAll(Day.values.toSet())) return 'everyday';
  return longestDayChain(days);
}

String daysToString(Iterable<Day> days) => days.isEmpty
    ? ''
    : SplayTreeSet<Day>.from(days,
            (a, b) => Day.values.indexOf(a).compareTo(Day.values.indexOf(b)))
        .map((day) => day.name)
        .join(',');
