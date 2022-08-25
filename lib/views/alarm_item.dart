import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/helper/day_to_string.dart';
import 'package:curtains/models/cronjob.dart';

class AlarmItem extends StatelessWidget {
  final BuildContext context;

  final CronJob alarm;
  const AlarmItem({
    required this.context,
    required this.alarm,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        expandedAlignment: Alignment.topLeft,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(const StadiumBorder()),
                  padding: MaterialStateProperty.all(
                      const EdgeInsets.fromLTRB(0, 16, 0, 8)),
                ),
                child: Text(alarm.time.format(context),
                    style: theme.textTheme.headline3),
                onPressed: () async {
                  final curtains = context.read<CurtainsCubit>();
                  TimeOfDay? selectedTime = await showTimePicker(
                    initialTime: alarm.time,
                    context: context,
                    builder: (context, child) => child != null
                        ? Theme(
                            data: theme,
                            child: child,
                          )
                        : const SizedBox.shrink(),
                  );
                  if (selectedTime != null) {
                    curtains.update(
                      CronJob.clone(from: alarm, newTime: selectedTime),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(daysToSentence(alarm.days)),
            ),
          ],
        ),
        children: [
          Wrap(
            children: [
              ...Day.values.map((d) => DayToggler(d: d, alarm: alarm))
            ],
          )
        ],
      ),
    );
  }
}

class DayToggler extends StatelessWidget {
  const DayToggler({
    Key? key,
    required this.d,
    required this.alarm,
  }) : super(key: key);

  final CronJob alarm;
  final Day d;

  @override
  Widget build(BuildContext context) {
    final active = alarm.days.contains(d);
    final theme = Theme.of(context);
    return ElevatedButton(
      style: active
          ? ButtonStyle(
              shape: MaterialStateProperty.all(const CircleBorder()),
              foregroundColor:
                  MaterialStateProperty.all(theme.primaryColorDark),
              backgroundColor:
                  MaterialStateProperty.all(theme.colorScheme.primary),
            )
          : ButtonStyle(
              shape: MaterialStateProperty.all(const CircleBorder()),
              foregroundColor:
                  MaterialStateProperty.all(theme.primaryColorLight),
              backgroundColor:
                  MaterialStateProperty.all(theme.colorScheme.surface),
            ),
      child: Text(
        d.name,
        style: const TextStyle(fontSize: 14),
      ),
      onPressed: () {
        var oldDays = alarm.days.toSet();
        if (!oldDays.remove(d)) oldDays.add(d);
        context.read<CurtainsCubit>().update(
              CronJob.clone(from: alarm, newDays: oldDays),
            );
      },
    );
  }
}
