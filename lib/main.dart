import 'dart:collection';

import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/views/connection.dart';
import 'package:flutter/material.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/views/alarmItem.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _client = MockedClientBloc();
  @override
  void dispose() {
    _client.disconnect();
    _client.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return 
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
        home: ClientProvider(
          client: _client,
          child:  MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  final String title = 'curtains';
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return StreamBuilder<SshState>(
      stream: client.connection,
      initialData: SshState.connecting,
      builder: (context, snapshot) {
        switch (snapshot.data) {
          case SshState.connected:
            return AlarmPage();
          default:
            return ConnectionInfo();
        }
      }
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
            onPressed: client.disconnect,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AddAlarmButton(),
    );
  }
}

class AddAlarmButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = ClientProvider.of(context).client;
    return FloatingActionButton(
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
                  client.alarmSink.add(CronJob(command: '', time: selectedTime, days: Day.values.toSet()));  
              }
            },
          tooltip: 'Add alarm',
          child: Icon(Icons.alarm_add),
        
      );
  }
}
