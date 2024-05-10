part of 'curtains_cubit.dart';

@immutable
sealed class CurtainsState {}

final class CurtainsDisconnected extends CurtainsState {
  final Object? error;

  CurtainsDisconnected([this.error]);
}

final class CurtainsConnecting extends CurtainsState {}

class CurtainsConnected extends CurtainsState {
  final UnmodifiableListView<CronJob> cronJobs;
  final UnmodifiableListView<AtJob> atJobs;
  CurtainsConnected(List<CronJob> cronjobs, List<AtJob> atjobs)
      : cronJobs =
            UnmodifiableListView(cronjobs..sort((a1, a2) => a2.compareTo(a1))),
        atJobs =
            UnmodifiableListView(atjobs..sort((a1, a2) => a2.compareTo(a1)));

  CurtainsBusy get busy => CurtainsBusy(
        cronJobs.toList(),
        atJobs.toList(),
      );

  List<Alarm> get alarms => [...cronJobs, ...atJobs];
}

final class CurtainsBusy extends CurtainsConnected {
  CurtainsBusy(super.cronjobs, super.atjobs);
}
