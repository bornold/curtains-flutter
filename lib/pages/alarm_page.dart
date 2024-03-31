import 'dart:async';

import 'package:curtains/views/add_alarm_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:curtains/views/alarm_item.dart';

class AlarmPage extends StatefulWidget {
  final List<CronJob> alarms;

  const AlarmPage(this.alarms, {Key? key}) : super(key: key);

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late final AppLifecycleListener _listener;

  final String title = 'curtains';

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () => context.read<CurtainsCubit>().refresh(),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.phonelink_off),
            onPressed: () => context.read<CurtainsCubit>().disconnect(),
          ),
          title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CurtainsCubit>().refresh();
          await Future.delayed(const Duration(milliseconds: 100));
        },
        child: ListView.builder(
          itemCount: widget.alarms.length,
          itemBuilder: (context, index) {
            final a = widget.alarms[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Dismissible(
                key: Key(a.uuid),
                resizeDuration: const Duration(milliseconds: 1000),
                direction: DismissDirection.endToStart,
                confirmDismiss: confirmDismissCallback(a, context),
                onDismissed: (dircetion) =>
                    context.read<CurtainsCubit>().addOrRemoveAlarm(a),
                background: Container(
                  alignment: AlignmentDirectional.centerStart,
                  child: Icon(
                    Icons.alarm_off,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                child: AlarmItem(context: context, alarm: a),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const AddAlarmButton(),
    );
  }

  ConfirmDismissCallback confirmDismissCallback(
      CronJob alarm, BuildContext context) {
    return (direction) {
      final completer = Completer<bool>();
      const duration = Duration(milliseconds: 1200);
      Timer(duration, () {
        if (!completer.isCompleted) completer.complete(true);
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: duration - const Duration(milliseconds: 200),
            content: Text('${alarm.time.format(context)} removed'),
            action: SnackBarAction(
              label: 'undo',
              onPressed: () {
                if (!completer.isCompleted) completer.complete(false);
              },
            ),
          ),
        );
      return completer.future;
    };
  }
}
