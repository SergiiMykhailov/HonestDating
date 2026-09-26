import 'package:bloc/bloc.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_event.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_state.dart';

class DiscoverScreenBloc
    extends Bloc<DiscoverScreenEvent, DiscoverScreenState> {
  DiscoverScreenBloc({required BaseDiscoveryRepository repository})
    : _repository = repository,
      super(const DiscoverScreenLoading()) {
    on<DiscoverScreenLoadRequested>(_onLoadRequested);
    on<DiscoverProfilePositionChanged>(_onProfilePositionChanged);
  }

  final BaseDiscoveryRepository _repository;

  Future<void> _onLoadRequested(
    DiscoverScreenLoadRequested event,
    Emitter<DiscoverScreenState> emit,
  ) async {
    try {
      final profiles = await _repository.loadProfiles();
      emit(DiscoverScreenLoaded(profiles: profiles));
    } catch (_) {
      emit(const DiscoverScreenFailure());
    }
  }

  void _onProfilePositionChanged(
    DiscoverProfilePositionChanged event,
    Emitter<DiscoverScreenState> emit,
  ) {
    final currentState = state;
    if (currentState is! DiscoverScreenLoaded ||
        event.index < 0 ||
        event.index >= currentState.profiles.length ||
        event.index == currentState.currentIndex) {
      return;
    }
    emit(
      DiscoverScreenLoaded(
        profiles: currentState.profiles,
        currentIndex: event.index,
      ),
    );
  }
}
