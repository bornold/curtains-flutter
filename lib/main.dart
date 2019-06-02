import 'package:curtains/constants.dart';
import 'package:curtains/datasource/client.dart';
import 'package:curtains/datasource/client_bloc.dart';
import 'package:curtains/models/connection_info.dart';
import 'package:curtains/views/alarmPage.dart';
import 'package:curtains/views/connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _client = Client();

  @override
  void initState() {
    getConnectionInfo();
    super.initState();
  }

  void getConnectionInfo() async {
    final storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    if  (prefs.getBool(autoconnect_prefs_key) ?? false) {
      final ip = prefs.getString(adress_prefs_key);
      final port = prefs.getInt(port_prefs_key);
      final passphrase = await storage.read(key: passphrase_sercure_key);

      if (ip != null && 
        port != null && 
        passphrase != null) {
          final sshkey = await DefaultAssetBundle.of(context).loadString(private_key_path);
          final cInfo = ConnectionInfo(host: ip, port: port, privatekey: sshkey, passphrase: passphrase);
          _client.connectionInfoSink.add(cInfo);
          _client.connectionEvents.add(ConnectionEvent.connect);
          return;
      }
    }

    _client.connectionEvents.add(ConnectionEvent.disconnect);
  }

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
        initialData: SshState.connecting,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ConnectionSettings(error: snapshot.error);
          }
          switch (snapshot.data) {
            case SshState.connecting:
              return Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor), 
                child: Center(child: CircularProgressIndicator()));
            case SshState.disconnected:
              return ConnectionSettings();
            default:
              return AlarmPage();
          }
        });
  }
}