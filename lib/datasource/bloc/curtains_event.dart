part of 'curtains_bloc.dart';

@immutable
abstract class CurtainsEvent {}

class ConnectEvent extends CurtainsEvent {
  final ConnectionInfo connectionInfo;
  ConnectEvent(this.connectionInfo);
}

class Disconnect extends CurtainsEvent {}

class RefreshEvent extends CurtainsEvent {}

class OpenEvent extends CurtainsEvent {}

class AddOrRemoveCroneJob extends CurtainsEvent {
  final CronJob cronJob;
  AddOrRemoveCroneJob(this.cronJob);
}

class UpdateCroneJob extends CurtainsEvent {
  final CronJob cronJob;
  UpdateCroneJob(this.cronJob);
}
