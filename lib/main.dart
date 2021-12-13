import 'package:curtains/datasource/bloc/curtains_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants.dart';
import 'models/connection_info.dart';
import 'views/alarm_page.dart';
import 'views/connection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CurtainsApp());
}

class CurtainsApp extends StatelessWidget {
  const CurtainsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.lime;
    return MaterialApp(
      title: 'curtains',
      theme: ThemeData.dark().copyWith(
        highlightColor: Colors.amber,
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: accentColor,
          cursorColor: accentColor,
          selectionHandleColor: accentColor,
        ),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              onSurface: accentColor[50],
              primary: accentColor,
              secondary: accentColor,
            ),
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(color: accentColor),
          titleTextStyle: TextStyle(color: Colors.grey[100], fontSize: 24),
        ),
        toggleableActiveColor: accentColor,
        textTheme: TextTheme(
          subtitle1: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
          ),
        ),
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: accentColor),
        cardTheme: const CardTheme(
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
        iconTheme: const IconThemeData(size: 42.0),
      ),
      home: BlocProvider(
        create: (context) => CurtainsBloc(),
        child: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    getConnectionInfo(context).then((connectionInfo) {
      if (connectionInfo != null) {
        BlocProvider.of<CurtainsBloc>(context)
            .add(ConnectEvent(connectionInfo));
      } else {
        BlocProvider.of<CurtainsBloc>(context).add(Disconnect());
      }
    });
    return BlocBuilder<CurtainsBloc, CurtainsState>(
      builder: (context, state) {
        if (state is CurtainsDisconnected) {
          return ConnectionSettings(error: state.error);
        } else if (state is CurtainsConnected) {
          return AlarmPage(state.alarms);
        }
        return Container(
          decoration:
              BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Future<ConnectionInfo?> getConnectionInfo(BuildContext context) async {
    if (kIsWeb) {
      return const RestfullConnectionInfo('localhost', 8080);
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(autoconnectPrefsKey) ?? false) {
      final ip = prefs.getString(adressPrefsKey);
      final port = prefs.getInt(portPrefsKey);
      final passphrase = prefs.getString(passphraseSercureKey);

      if (ip != null && port != null && passphrase != null) {
        final sshkey =
            await DefaultAssetBundle.of(context).loadString(privateKeyPath);
        return SSHConnectionInfo(
            host: ip, port: port, privatekey: sshkey, passphrase: passphrase);
      }
    }
    return null;
  }
}
