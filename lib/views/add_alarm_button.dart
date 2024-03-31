import 'package:curtains/datasource/bloc/curtains_cubit.dart';
import 'package:curtains/models/cronjob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            final curtains = context.read<CurtainsCubit>();
            TimeOfDay? selectedTime = await showTimePicker(
              initialTime: TimeOfDay.fromDateTime(
                DateTime.now().add(
                  const Duration(minutes: 1),
                ),
              ),
              context: context,
              builder: (context, child) => child != null
                  ? Theme(
                      data: Theme.of(context),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            );
            if (selectedTime != null) {
              curtains.addOrRemoveAlarm(
                CronJob.everyday(time: selectedTime),
              );
            }
          },
          tooltip: 'add alarm',
          child: const Icon(Icons.alarm_add),
        ),
        SizedBox(
          width: 56,
          height: 56,
          child: BlocBuilder<CurtainsCubit, CurtainsState>(
            builder: (context, state) {
              return state is CurtainsBusy
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(openColor),
                    )
                  : FloatingActionButton(
                      backgroundColor: openColor,
                      onPressed: () => context.read<CurtainsCubit>().open(),
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
