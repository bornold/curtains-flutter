import 'dart:collection';

import 'package:curtains/datasource/client_bloc.dart';
import 'package:flutter/material.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/views/alarmItem.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return ClientProvider(
      client: ClientBloc(),
      child: 
        MaterialApp(
        title: 'curtains',
        theme: ThemeData.dark().copyWith(
          textTheme: TextTheme(
            title: TextStyle(color: Colors.grey, fontSize: 42),
          ),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(borderRadius: 
              BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                  bottomLeft: Radius.circular(4.0),
                  bottomRight: Radius.circular(4.0),
              ),
            ),
            elevation: 4,
            margin: EdgeInsets.fromLTRB(4, 4, 4, 0)
            ),
          buttonTheme: ButtonThemeData(
            minWidth: 36, 
            padding: EdgeInsets.zero,)
        ),      
        home: MyHomePage(title: 'curtains'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  Widget build(BuildContext context) {
  final client = ClientProvider.of(context).client;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.phonelink_off), onPressed: () {},
            color: Theme.of(context).accentColor,
          ),
          title: Text(title)
        ),
      body: RefreshIndicator(
        onRefresh: () => client.refresh(forceRefresh: true),
        child: StreamBuilder<UnmodifiableListView<CronJob>>(
          stream: client.alarms, 
          builder: (context, snapshot) => 
            snapshot.hasData ? 
              ListView(children: 
                snapshot.data
                  .map<Widget>((a) => AlarmItem(alarm: a, context: context,))
                  .followedBy([Container(height: 80,)])
                  .toList())
            : Center(child: CircularProgressIndicator())
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AddAlarmButton(),
    );
  }
}

class AddAlarmButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return Padding( padding: const EdgeInsets.all(18),
          child:FloatingActionButton(
            onPressed: () async { 
              TimeOfDay selectedTime = await showTimePicker(
                initialTime: TimeOfDay.now(),
                context: context,
                  builder: (context, child) => 
                    Theme(
                      data: Theme.of(context),
                      child: child,)
              );
              if (selectedTime != null) {
                  client.addition.add(CronJob(command: '', time: selectedTime, days: Day.values.toSet()));  
              }
            },
          tooltip: 'Add alarm',
          child: Icon(Icons.alarm_add),
        ),
      );
  }
}
