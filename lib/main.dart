import 'package:curtains/datasource/client.dart';
import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/views/alarmPage.dart';
import 'package:curtains/views/connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _client = Client();

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  } 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'curtains',
      theme: ThemeData.dark().copyWith(
        brightness: Brightness.dark,
        textTheme: TextTheme(
          title: TextStyle(color: Colors.grey, fontSize: 42),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
              bottomLeft: Radius.circular(4.0),
              bottomRight: Radius.circular(4.0),
            ),
          ),
          elevation: 4,
          margin: EdgeInsets.fromLTRB(4, 4, 4, 0)),
          buttonTheme: ButtonThemeData(
            minWidth: 36,
            padding: EdgeInsets.zero,
          ),
          iconTheme: IconThemeData(size: 42.0),
      ),
      home: ClientProvider(
        client: _client,
        child: MainPage(),
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
        initialData: SshState.disconnected,
        builder: (context, snapshot) {
          switch (snapshot.data) {
            case SshState.disconnected:
              return ConnectionInfo();
            default:
              return AlarmPage();
          }
        });
  }
}