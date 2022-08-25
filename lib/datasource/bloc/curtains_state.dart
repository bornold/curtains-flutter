part of 'curtains_cubit.dart';

@immutable
abstract class CurtainsState extends Equatable {
  @override
  bool get stringify => true;
}

class CurtainsDisconnected extends CurtainsState {
  final Object? error;

  CurtainsDisconnected([this.error]);

  @override
  List<Object?> get props => [error];
}

class CurtainsConnecting extends CurtainsState {
  @override
  List<Object> get props => [];
}

class CurtainsConnected extends CurtainsState {
  final UnmodifiableListView<CronJob> alarms;
  CurtainsConnected(List<CronJob> cronjobs)
      : alarms =
            UnmodifiableListView(cronjobs..sort((a1, a2) => a2.compareTo(a1)));

  @override
  List<Object> get props => alarms;
}

class CurtainsBusy extends CurtainsConnected {
  CurtainsBusy(List<CronJob> cronjobs) : super(cronjobs);
}
