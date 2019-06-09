import 'dart:async';

import '../models/connection_info.dart';
import '../models/cronjob.dart';
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
  Stream<ConnectionStatus> get connection;
  Stream<Availability> get availability;
  Stream<CronJob> get updatedAlarms;
  Sink<CronJob> get alarmSink;
  Sink<ConnectionEvent> get connectionEvents;
  Sink<CronJob> get updateAlarmSink;
  Sink<ConnectionInfo> get connectionInfoSink;

  void dispose();
}

enum ConnectionEvent { connect, disconnect, refresh, open }

enum ConnectionStatus { disconnected, connecting, connected, loadning }

enum Availability { idle, busy }
