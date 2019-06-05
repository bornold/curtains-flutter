import 'dart:async';
import 'dart:collection';

import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/views/alarmItem.dart';
import 'package:flutter/material.dart';

class AddAlarmButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    final openColor = Theme.of(context).highlightColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        FloatingActionButton( 
          onPressed: () async {
            TimeOfDay selectedTime = await showTimePicker(
                initialTime: TimeOfDay.fromDateTime(DateTime.now().add( Duration(minutes: 1))) ,
                context: context,
                builder: (context, child) => Theme(
                      data: Theme.of(context),
                      child: child,
                    )
              );
            if (selectedTime != null) {
              client.alarmSink.add(CronJob.everyday(time: selectedTime));
            }
          },
          tooltip: 'add alarm',
          child: Icon(Icons.alarm_add),
        ),
        SizedBox(
          width: 56,
          height: 56,
          child: StreamBuilder<SshState>(
            stream: client.connection,
            initialData: SshState.busy,
            builder: (context, snapshot) {
              final busy = snapshot.data == SshState.busy;
              return busy ? 
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(openColor),) :
                FloatingActionButton(
                  backgroundColor: openColor,
                  onPressed: () => client.connectionEvents.add(ConnectionEvent.open),
                  tooltip: 'open curtains',
                  child: Icon(Icons.flare),
                );
            }
          ),
        ),
      ],
    );
  }
}

class AlarmPage extends StatelessWidget {
  final String title = 'curtains';
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.phonelink_off),
            onPressed: () =>
                client.connectionEvents.add(ConnectionEvent.disconnect),
          ),
          title: Text(title)),
      body: RefreshIndicator(
          onRefresh: () async {
            client.connectionEvents.add(ConnectionEvent.refresh);
            await Future.delayed(Duration(milliseconds: 50));
            await for (var value in client.connection) {
              if (value == SshState.connected) {
                return value;
              }
            }
          },
          child: StreamBuilder<UnmodifiableListView<CronJob>>(
              stream: client.alarms,
              builder: (context, snapshot) => 
                snapshot.hasData ? 
                  ListView(
                    children: snapshot.data.map<Widget>(
                      (a) => 
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Dismissible(
                              key: Key(a.uuid),
                              resizeDuration: Duration(milliseconds: 1000),
                              direction: DismissDirection.startToEnd,
                              confirmDismiss:
                                  confirmDismissCallback(a, context),
                              onDismissed: (dircetion) =>
                                  client.alarmSink.add(a),
                              background: Container(
                                alignment: AlignmentDirectional.centerStart,
                                child: Icon(
                                  Icons.alarm_off,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              child: AlarmItem(context: context, initAlarm: a),
                            ),
                          ),
                    )
                          .followedBy([
                      Container(
                        height: 80,
                      )
                    ]).toList())
                  : Center(child: CircularProgressIndicator())
          )
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AddAlarmButton(),
    );
  }

  ConfirmDismissCallback confirmDismissCallback(
      CronJob alarm, BuildContext context) {
    return (direction) {
      final c = Completer<bool>();
      final duration = Duration(milliseconds: 1200);
      Timer(duration, () {
        if (!c.isCompleted) c.complete(true);
      });
      final scaffold = Scaffold.of(context);
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
          duration: duration - Duration(milliseconds: 200),
          content: Text('${alarm.time.format(context)} removed'),
          action: SnackBarAction(
              label: 'undo',
              onPressed: () {
                if (!c.isCompleted) c.complete(false);
              })));
      return c.future;
    };
  }
}
