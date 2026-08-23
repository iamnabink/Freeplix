part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load every rail on the home page. Also used to retry after a failure.
final class HomeRequested extends HomeEvent {
  const HomeRequested();
}

/// Move the spotlight to the next trending title.
final class HomeSpotlightAdvanced extends HomeEvent {
  const HomeSpotlightAdvanced();
}
