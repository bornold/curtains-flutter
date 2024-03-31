import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
