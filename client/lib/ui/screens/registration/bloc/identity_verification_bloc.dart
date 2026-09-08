import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/identity_verification_result.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';

sealed class IdentityVerificationEvent {
  const IdentityVerificationEvent();
}

class IdentityVerificationRequested extends IdentityVerificationEvent {
  const IdentityVerificationRequested();
}

enum IdentityVerificationPhase { ready, inProgress, completed, needsRetry }

class IdentityVerificationState {
  const IdentityVerificationState({required this.phase, this.outcome});

  const IdentityVerificationState.ready()
    : phase = IdentityVerificationPhase.ready,
      outcome = null;

  final IdentityVerificationPhase phase;
  final IdentityVerificationOutcome? outcome;
}

class IdentityVerificationBloc
    extends Bloc<IdentityVerificationEvent, IdentityVerificationState> {
  IdentityVerificationBloc({
    required BaseIdentityVerificationRepository repository,
  }) : _repository = repository,
       super(const IdentityVerificationState.ready()) {
    on<IdentityVerificationRequested>(_onRequested);
  }

  final BaseIdentityVerificationRepository _repository;

  Future<void> _onRequested(
    IdentityVerificationRequested event,
    Emitter<IdentityVerificationState> emit,
  ) async {
    emit(
      const IdentityVerificationState(
        phase: IdentityVerificationPhase.inProgress,
      ),
    );

    final result = await _repository.startLivenessCheck();
    final phase = result.outcome == IdentityVerificationOutcome.verified
        ? IdentityVerificationPhase.completed
        : IdentityVerificationPhase.needsRetry;

    emit(IdentityVerificationState(phase: phase, outcome: result.outcome));
  }
}
