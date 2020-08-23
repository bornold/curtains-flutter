import 'package:curtains/datasource/bloc/curtains_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../helper/dayToString.dart';
import '../models/cronjob.dart';
import 'package:flutter/material.dart';

class AlarmItem extends StatelessWidget {
  final BuildContext context;

  final CronJob alarm;
  const AlarmItem({
    @required this.context,
    @required this.alarm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: FlatButton(
                  shape: StadiumBorder(),
                  padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                  child: Text('${alarm.time.format(context)}',
                      style: theme.textTheme.headline3),
                  onPressed: () async {
                    TimeOfDay selectedTime = await showTimePicker(
                      initialTime: alarm.time,
                      context: context,
                      builder: (BuildContext context, Widget child) => Theme(
                        data: theme,
                        child: child,
                      ),
                    );
                    if (selectedTime != null) {
                      BlocProvider.of<CurtainsBloc>(context).add(UpdateCroneJob(
                          CronJob.clone(from: alarm, newTime: selectedTime)));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  daysToSentence(alarm.days),
                ),
              ),
            ]),
        children: [
          DayToggleBar(context: context, alarm: alarm),
        ],
      ),
    );
  }
}

class DayToggleBar extends StatelessWidget {
  final BuildContext context;

  final CronJob alarm;
  const DayToggleBar({
    Key key,
    @required this.context,
    @required this.alarm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ButtonBar(
          mainAxisSize: MainAxisSize.min,
          children: Day.values.map((d) {
            final active = alarm.days.contains(d);
            return RaisedButton(
              elevation: 8,
              shape: CircleBorder(),
              textColor:
                  active ? theme.primaryColorDark : theme.primaryColorLight,
              color: active ? theme.accentColor : theme.accentIconTheme.color,
              child: Text(
                dayToString(d),
                style: TextStyle(fontSize: 14),
              ),
              onPressed: () {
                var oldDays = alarm.days.toSet();
                if (!oldDays.remove(d)) oldDays.add(d);
                BlocProvider.of<CurtainsBloc>(context).add(UpdateCroneJob(
                    CronJob.clone(from: alarm, newDays: oldDays)));
              },
            );
          }).toList()),
    );
  }
}
