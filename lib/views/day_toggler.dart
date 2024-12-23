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
      shape: const WidgetStatePropertyAll(CircleBorder()),
      foregroundColor: WidgetStatePropertyAll(theme.primaryColorDark),
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.primary),
    );
    final inactiveButtonStyle = activeByttonStyle.copyWith(
      foregroundColor: WidgetStatePropertyAll(theme.primaryColorLight),
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
    );
    return TextButton(
      style: alarm.days.contains(d) ? activeByttonStyle : inactiveButtonStyle,
      onPressed: () => context.read<CurtainsCubit>().updateDay(alarm, d),
      child: Text(d.name),
    );
  }
}
