import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/discovery_filters.dart';
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
    on<DiscoverFiltersChanged>(_onFiltersChanged);
  }

  final BaseDiscoveryRepository _repository;

  Future<void> _onLoadRequested(
    DiscoverScreenLoadRequested event,
    Emitter<DiscoverScreenState> emit,
  ) async {
    try {
      final filters = event.filters ?? _activeFilters;
      final profiles = await _repository.loadProfiles(filters: filters);
      final availableInterests = <String>{
        ..._availableInterests,
        ...profiles.expand((profile) => profile.interests),
      }.toList(growable: false)..sort();
      emit(
        DiscoverScreenLoaded(
          profiles: profiles,
          filters: filters,
          availableInterests: availableInterests,
        ),
      );
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
        filters: currentState.filters,
        availableInterests: currentState.availableInterests,
      ),
    );
  }

  void _onFiltersChanged(
    DiscoverFiltersChanged event,
    Emitter<DiscoverScreenState> emit,
  ) {
    add(DiscoverScreenLoadRequested(filters: event.filters));
  }

  DiscoveryFilters get _activeFilters {
    final currentState = state;
    return currentState is DiscoverScreenLoaded
        ? currentState.filters
        : DiscoveryFilters.none;
  }

  List<String> get _availableInterests {
    final currentState = state;
    return currentState is DiscoverScreenLoaded
        ? currentState.availableInterests
        : const <String>[];
  }
}
