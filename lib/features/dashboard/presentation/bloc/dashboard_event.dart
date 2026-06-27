part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
}

class DashboardNoop extends DashboardEvent {
  const DashboardNoop();
  @override
  List<Object> get props => [];
}
