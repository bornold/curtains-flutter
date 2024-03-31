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
                    style: theme.textTheme.headlineSmall),
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
