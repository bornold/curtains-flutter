import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DayToggler extends StatelessWidget {
  const DayToggler({
    super.key,
    required this.d,
    required this.alarm,
  });

  final CronJob alarm;
  final Day d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeByttonStyle = ButtonStyle(
      visualDensity: const VisualDensity(horizontal: -4.0, vertical: 0.0),
      shape: MaterialStateProperty.all(const CircleBorder()),
      foregroundColor: MaterialStateProperty.all(theme.primaryColorDark),
      backgroundColor: MaterialStateProperty.all(theme.colorScheme.primary),
    );
    final inactiveButtonStyle = activeByttonStyle.copyWith(
      foregroundColor: MaterialStateProperty.all(theme.primaryColorLight),
      backgroundColor: MaterialStateProperty.all(theme.colorScheme.surface),
    );
    return TextButton(
      style: alarm.days.contains(d) ? activeByttonStyle : inactiveButtonStyle,
      child: Text(d.name),
      onPressed: () {
        var oldDays = alarm.days.toSet();
        if (!oldDays.remove(d)) oldDays.add(d);
        context
            .read<CurtainsCubit>()
            .update(CronJob.clone(from: alarm, newDays: oldDays));
      },
    );
  }
}
