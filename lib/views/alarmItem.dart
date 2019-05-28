import 'dart:async';

import 'package:curtains/datasource/client_bloc.dart';
import 'package:flutter/material.dart';
import 'package:curtains/models/cronjob.dart';

class AlarmItem extends StatelessWidget {
  const AlarmItem({
    @required this.context,
    @required this.alarm,
  });

  final BuildContext context;
  final CronJob alarm;

  @override
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Dismissible(
        key: Key(alarm.uuid),
        confirmDismiss: confirmDismissCallback(context),
        onDismissed: 
          (dircetion) => client.alarmSink.add(alarm),
        child: Card(
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: FlatButton(
                    shape: StadiumBorder(), 
                    padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Text('${alarm.time.format(context)}', style: Theme.of(context).textTheme.title), 
                    onPressed: () async { 
                      TimeOfDay selectedTime = await showTimePicker(
                          initialTime: alarm.time,
                          context: context,
                            builder: (BuildContext context, Widget child) =>
                              Theme(data: Theme.of(context), child: child,)
                        );
                      if (selectedTime != null) {
                        client.updateItem(alarm, CronJob(command: alarm.command, time: selectedTime, days: alarm.days.toSet()));
                      }
                    },),
                ), 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(alarm.days.length == 7 ? 'Everyday' : alarm.days.map((d) => enumName(d)).join(', '),),
                  ),
              ]
            ),
            children: [
              DayToggleBar(context: context, alarm: alarm),
            ],
          ),
      ), 
    ));
  }

  ConfirmDismissCallback confirmDismissCallback(BuildContext context) {
    return (direction) {
      final c = Completer<bool>();
      final duration = Duration(seconds: 1);
      Timer(duration, () => 
        c.complete(true));
      final scaffold = Scaffold.of(context);
      scaffold.removeCurrentSnackBar();  
      scaffold.showSnackBar(
          SnackBar(
            duration: duration - Duration(milliseconds: 200),
            content: Text("$alarm dismissed"),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                if (!c.isCompleted) c.complete(false);
              }
            )
          )
        );
        return c.future;
      };
  }
}

class DayToggleBar extends StatelessWidget {
  const DayToggleBar({
    Key key,
    @required this.context,
    @required this.alarm,
  }) : super(key: key);

  final BuildContext context;
  final CronJob alarm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = ClientProvider.of(context).client;
    return ButtonBar(
      mainAxisSize: MainAxisSize.min,
      children: Day.values.map((d) {
        final active = alarm.days.contains(d);
        return FlatButton(
          shape: CircleBorder(), 
          textColor: active ? theme.primaryColorDark : theme.primaryColorLight,
          color: active ? theme.primaryIconTheme.color : theme.accentIconTheme.color, 
          child: Text(enumName(d), style: TextStyle(fontSize: 14),), 
          onPressed: () {
            if (!alarm.days.remove(d)) alarm.days.add(d);   
            //client.updateItem(alarm, CronJob(command: alarm.command, time: alarm.time, days: alarm.days));
          },
        );
      }
    ).toList());
  }
}