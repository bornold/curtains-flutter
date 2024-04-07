import 'package:curtains/theme.dart';
import 'package:curtains/views/day_toggler.dart';
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        shape: cardShape,
        initiallyExpanded: true,
        expandedAlignment: Alignment.topLeft,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TimePickerButton(alarm: alarm),
            Text(
              daysToSentence(alarm.days),
              softWrap: false,
            ),
          ],
        ),
        children: [
          Wrap(
            children: <Widget>[
              ...Day.values.map((d) => DayToggler(d: d, alarm: alarm)),
            ],
          ),
        ],
      ),
    );
  }
}

class TimePickerButton extends StatelessWidget {
  const TimePickerButton({
    super.key,
    required this.alarm,
  });

  final CronJob alarm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        visualDensity: VisualDensity.compact,
        padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
      ),
      child: Text(
        alarm.time.format(context),
        style: theme.textTheme.headlineSmall,
      ),
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
    );
  }
}
