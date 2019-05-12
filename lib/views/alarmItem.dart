import 'package:curtains/datasource/mockJobs.dart';
import 'package:flutter/material.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:provider/provider.dart';

class AlarmItem extends StatelessWidget {
  const AlarmItem({
    Key key,
    @required this.context,
    @required this.alarm,
  }) : super(key: key);

  final BuildContext context;
  final CronJob alarm;

  @override
  Widget build(BuildContext context) {
    final _client = Provider.of<MockClient>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
                      _client.updateItem(alarm, CronJob(command: 'command', time: selectedTime, days: alarm.days.toSet()));
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
            new DayToggleBar(context: context, alarm: alarm), 
            IconButton(
              icon: Icon(Icons.delete), 
              onPressed: () {
                  _client.delete(alarm);
              },
            ),
          ],
        ),
      ),
    );
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
    final _client = Provider.of<MockClient>(context);
    return ButtonBar(
      mainAxisSize: MainAxisSize.min,
      children: Day.values.map((d) =>
      FlatButton(
        shape: CircleBorder(), 
        textColor: alarm.days.contains(d) ? theme.primaryColorDark : theme.primaryColorLight,
        color: alarm.days.contains(d) ? theme.primaryIconTheme.color : theme.accentIconTheme.color, 
        child: Text(enumName(d), style: TextStyle(fontSize: 14),), 
        onPressed: () {
          _client.updateItem(alarm, CronJob(command: alarm.command, time: alarm.time, days: alarm.days));
        },)
    ).toList());
  }
}