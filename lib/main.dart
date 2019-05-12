import 'package:flutter/material.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/datasource/mockJobs.dart';
import 'package:curtains/views/alarmItem.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( builder: (context) => MockClient(),
        child: MaterialApp(
        title: 'Curtains',
        theme: ThemeData.dark().copyWith(
          textTheme:  TextTheme(
            title: TextStyle(color: Colors.grey, fontSize: 42),
          ),
          cardTheme: CardTheme(
            shape: SuperellipseShape(borderRadius: BorderRadius.all(Radius.circular(32))),
            margin: EdgeInsets.fromLTRB(4, 4, 4, 0)
            ),
          buttonTheme: ButtonThemeData(
            minWidth: 36, 
            padding: EdgeInsets.zero,
            )
        ),      
        home: MyHomePage(title: 'Curtains'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final _client = Provider.of<MockClient>(context);
    final _alarms = _client.alarmsNow;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.phonelink_off), onPressed: () {},),
        title: Text(widget.title)
        ),
      body: ListView(children: _alarms.map<Widget>((a) => AlarmItem(alarm: a, context: context,)).toList()..addAll([Container(height: 80,)])),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: 
        Padding( padding: const EdgeInsets.all(18),
          child:FloatingActionButton(
            onPressed: () async { 
              TimeOfDay selectedTime = await showTimePicker(
                initialTime: TimeOfDay.now(),
                context: context,
                  builder: (BuildContext context, Widget child) {
                      return Theme(
                        data: Theme.of(context),
                        child: child,
                      );
                  }
              );
              if (selectedTime != null) {
                setState(() {
                  _client.add(CronJob(command: '', time: selectedTime, days: Day.values.toSet()));  
                });
              }
            },
          tooltip: 'Add alarm',
          child: Icon(Icons.alarm_add),
        ),
      )
    );
  }
}
