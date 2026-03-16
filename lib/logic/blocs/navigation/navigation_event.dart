import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class ChangeTab extends NavigationEvent {
  final int index;

  const ChangeTab(this.index);

  @override
  List<Object> get props => [index];
}
