import 'dart:async';

import 'package:curtains/datasource/bloc/curtains_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cronjob.dart';
import 'alarm_item.dart';
import 'package:flutter/material.dart';

class AddAlarmButton extends StatelessWidget {
  const AddAlarmButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final openColor = Theme.of(context).highlightColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        FloatingActionButton(
          onPressed: () async {
            TimeOfDay? selectedTime = await showTimePicker(
              initialTime: TimeOfDay.fromDateTime(
                  DateTime.now().add(const Duration(minutes: 1))),
              context: context,
              builder: (context, child) => child != null
                  ? Theme(
                      data: Theme.of(context),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            );
            if (selectedTime != null) {
              BlocProvider.of<CurtainsBloc>(context).add(
                  AddOrRemoveCroneJob(CronJob.everyday(time: selectedTime)));
            }
          },
          tooltip: 'add alarm',
          child: const Icon(Icons.alarm_add),
        ),
        SizedBox(
          width: 56,
          height: 56,
          child: BlocBuilder<CurtainsBloc, CurtainsState>(
            builder: (context, state) {
              return state is CurtainsBusy
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(openColor),
                    )
                  : FloatingActionButton(
                      backgroundColor: openColor,
                      onPressed: () => BlocProvider.of<CurtainsBloc>(context)
                          .add(OpenEvent()),
                      tooltip: 'open curtains',
                      child: const Icon(Icons.flare),
                    );
            },
          ),
        ),
      ],
    );
  }
}

class AlarmPage extends StatelessWidget {
  final List<CronJob> alarms;
  final String title = 'curtains';

  const AlarmPage(this.alarms, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.phonelink_off),
            onPressed: () =>
                BlocProvider.of<CurtainsBloc>(context).add(Disconnect()),
          ),
          title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () async {
          BlocProvider.of<CurtainsBloc>(context).add(RefreshEvent());
          await Future.delayed(const Duration(milliseconds: 100));
        },
        child: ListView.builder(
          itemCount: alarms.length,
          itemBuilder: (BuildContext context, int index) {
            final a = alarms[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Dismissible(
                key: Key(a.uuid),
                resizeDuration: const Duration(milliseconds: 1000),
                direction: DismissDirection.startToEnd,
                confirmDismiss: confirmDismissCallback(a, context),
                onDismissed: (dircetion) =>
                    BlocProvider.of<CurtainsBloc>(context)
                        .add(AddOrRemoveCroneJob(a)),
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
      final c = Completer<bool>();
      const duration = Duration(milliseconds: 1200);
      Timer(duration, () {
        if (!c.isCompleted) c.complete(true);
      });
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
          duration: duration - const Duration(milliseconds: 200),
          content: Text('${alarm.time.format(context)} removed'),
          action: SnackBarAction(
              label: 'undo',
              onPressed: () {
                if (!c.isCompleted) c.complete(false);
              })));
      return c.future;
    };
  }
}
