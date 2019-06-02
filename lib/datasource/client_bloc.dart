import 'dart:async';

import 'package:curtains/models/connection_info.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';

class ClientProvider extends InheritedWidget {
  final ClientBloc client;

  ClientProvider({this.client, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(ClientProvider oldWidget) => true;

  static ClientProvider of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(ClientProvider);
}
abstract class ClientBloc { 
  Stream<List<CronJob>> get alarms;
  Stream<SshState> get connection;
  Stream<CronJob> get updatedAlarms;
  Sink<CronJob> get alarmSink;
  Sink<ConnectionEvent> get connectionEvents;
  Sink<CronJob> get updateAlarmSink;
  Sink<ConnectionInfo> get connectionInfoSink;

  void dispose();
}

enum ConnectionEvent {
  connect,
  disconnect,
  refresh,
  open
}

enum SshState {
  disconnected,
  connecting,
  connected,
  busy
}
