import 'package:bloc/bloc.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_event.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_state.dart';

class InteractionCenterBloc
    extends Bloc<InteractionCenterEvent, InteractionCenterState> {
  InteractionCenterBloc({
    required BaseDiscoveryRepository repository,
    InteractionSection initialSection = InteractionSection.matches,
  }) : _initialSection = initialSection,
       _repository = repository,
       super(const InteractionCenterLoading()) {
    on<InteractionCenterLoadRequested>(_onLoad);
    on<InteractionCenterModeChanged>(_onModeChanged);
    on<InteractionCenterSectionChanged>(_onSectionChanged);
  }

  final BaseDiscoveryRepository _repository;
  final InteractionSection _initialSection;

  Future<void> _onLoad(
    InteractionCenterLoadRequested event,
    Emitter<InteractionCenterState> emit,
  ) async {
    try {
      emit(
        InteractionCenterLoaded(
          profiles: await _repository.loadRelationshipProfiles(),
          mode: _initialSection.isRomance
              ? InteractionCenterMode.romance
              : InteractionCenterMode.friendship,
          section: _initialSection,
        ),
      );
    } catch (_) {
      emit(const InteractionCenterFailure());
    }
  }

  void _onModeChanged(
    InteractionCenterModeChanged event,
    Emitter<InteractionCenterState> emit,
  ) {
    final current = state;
    if (current is! InteractionCenterLoaded) return;
    emit(
      current.copyWith(
        mode: event.mode,
        section: event.mode == InteractionCenterMode.romance
            ? InteractionSection.matches
            : InteractionSection.friends,
      ),
    );
  }

  void _onSectionChanged(
    InteractionCenterSectionChanged event,
    Emitter<InteractionCenterState> emit,
  ) {
    final current = state;
    if (current is InteractionCenterLoaded) {
      emit(current.copyWith(section: event.section));
    }
  }
}
