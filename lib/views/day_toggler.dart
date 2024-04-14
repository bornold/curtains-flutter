import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/models/alarms.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DayToggler extends StatelessWidget {
  const DayToggler({
    super.key,
    required this.d,
    required this.alarm,
  });

  final Alarm alarm;
  final Day d;

  @override
  Widget build(BuildContext context) {
    final alarm = this.alarm;
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
      onPressed: () => context.read<CurtainsCubit>().updateDay(alarm, d),
      child: Text(d.name),
    );
  }
}
