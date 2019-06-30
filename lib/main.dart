import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'constants.dart';
import 'datasource/client.dart';
import 'datasource/client_bloc.dart';
import 'models/connection_info.dart';
import 'views/alarmPage.dart';
import 'views/connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Crashlytics.instance.enableInDevMode = true;

  // Pass all uncaught errors to Crashlytics.
  FlutterError.onError = (FlutterErrorDetails details) {
    Crashlytics.instance.onError(details);
  };
  runApp(CurtainsApp());
}

class CurtainsApp extends StatefulWidget {
  @override
  _CurtainsAppState createState() => _CurtainsAppState();
}

class _CurtainsAppState extends State<CurtainsApp> {
  final _client = Client();

  @override
  void initState() {
    getConnectionInfo();
    super.initState();
  }

  void getConnectionInfo() async {
    final storage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(autoconnect_prefs_key) ?? false) {
      final ip = prefs.getString(adress_prefs_key);
      final port = prefs.getInt(port_prefs_key);
      final passphrase = await storage.read(key: passphrase_sercure_key);

      if (ip != null && port != null && passphrase != null) {
        final sshkey =
            await DefaultAssetBundle.of(context).loadString(private_key_path);
        final cInfo = ConnectionInfo(
            host: ip, port: port, privatekey: sshkey, passphrase: passphrase);
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
    final accentColor = Colors.lime;
    final highlightColor = Colors.amber;
    return MaterialApp(
      title: 'curtains',
      theme: ThemeData.dark().copyWith(
        accentColor: accentColor,
        highlightColor: highlightColor,
        textSelectionColor: accentColor,
        cursorColor: accentColor,
        textSelectionHandleColor: accentColor,
        appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(color: accentColor),
            textTheme: TextTheme(
                title: TextStyle(color: Colors.grey[100], fontSize: 24))),
        toggleableActiveColor: accentColor,
        textTheme: TextTheme(
          subhead: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
          ),
        ),
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: accentColor),
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
          colorScheme: ColorScheme.fromSwatch(primarySwatch: accentColor),
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
    return StreamBuilder<ConnectionStatus>(
        stream: client.connection,
        initialData: ConnectionStatus.connecting,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ConnectionSettings(error: snapshot.error);
          }
          switch (snapshot.data) {
            case ConnectionStatus.connecting:
              return Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor),
                  child: Center(child: CircularProgressIndicator()));
            case ConnectionStatus.disconnected:
              return ConnectionSettings();
            default:
              return AlarmPage();
          }
        });
  }
}
