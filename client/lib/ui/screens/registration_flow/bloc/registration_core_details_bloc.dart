import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

enum RegistrationCoreDetailsStep { firstName, lastName, gender, dateOfBirth }

extension RegistrationCoreDetailsStepDetails on RegistrationCoreDetailsStep {
  /// These focused pages are one registration stage: core details.
  int get registrationStep => 2;

  RegistrationCoreDetailsStep? get next {
    final nextIndex = index + 1;
    return nextIndex < RegistrationCoreDetailsStep.values.length
        ? RegistrationCoreDetailsStep.values[nextIndex]
        : null;
  }
}

sealed class RegistrationCoreDetailsEvent {
  const RegistrationCoreDetailsEvent();
}

class RegistrationFirstNameChanged extends RegistrationCoreDetailsEvent {
  const RegistrationFirstNameChanged(this.value);

  final String value;
}

class RegistrationLastNameChanged extends RegistrationCoreDetailsEvent {
  const RegistrationLastNameChanged(this.value);

  final String value;
}

class RegistrationGenderSelected extends RegistrationCoreDetailsEvent {
  const RegistrationGenderSelected(this.value);

  final String value;
}

class RegistrationDateOfBirthChanged extends RegistrationCoreDetailsEvent {
  const RegistrationDateOfBirthChanged(this.value);

  final String value;
}

class RegistrationCoreDetailsContinueRequested
    extends RegistrationCoreDetailsEvent {
  const RegistrationCoreDetailsContinueRequested();
}

class RegistrationCoreDetailsState {
  const RegistrationCoreDetailsState({
    required this.step,
    required this.draft,
    required this.dateOfBirthInput,
    this.navigationRequest = 0,
  });

  final RegistrationCoreDetailsStep step;
  final ProfileSetupDraft draft;
  final String dateOfBirthInput;
  final int navigationRequest;

  DateTime? get parsedDateOfBirth => _parseDateOfBirth(dateOfBirthInput);

  bool get isDateOfBirthFormatValid => parsedDateOfBirth != null;

  bool get isAdult {
    final dateOfBirth = parsedDateOfBirth;
    return dateOfBirth != null && _ageFor(dateOfBirth) >= 18;
  }

  bool get canContinue {
    switch (step) {
      case RegistrationCoreDetailsStep.firstName:
        return draft.firstName.trim().isNotEmpty;
      case RegistrationCoreDetailsStep.lastName:
        return draft.lastName.trim().isNotEmpty;
      case RegistrationCoreDetailsStep.gender:
        return draft.gender.isNotEmpty;
      case RegistrationCoreDetailsStep.dateOfBirth:
        return isAdult;
    }
  }

  String? get dateOfBirthError {
    if (step != RegistrationCoreDetailsStep.dateOfBirth ||
        dateOfBirthInput.trim().isEmpty ||
        isDateOfBirthFormatValid) {
      return null;
    }
    return 'Enter a real date as DD.MM.YYYY.';
  }

  String? get eligibilityError {
    if (step == RegistrationCoreDetailsStep.dateOfBirth &&
        isDateOfBirthFormatValid &&
        !isAdult) {
      return 'You need to be at least 18 to join Honest Dating.';
    }
    return null;
  }

  RegistrationCoreDetailsState copyWith({
    ProfileSetupDraft? draft,
    String? dateOfBirthInput,
    int? navigationRequest,
  }) {
    return RegistrationCoreDetailsState(
      step: step,
      draft: draft ?? this.draft,
      dateOfBirthInput: dateOfBirthInput ?? this.dateOfBirthInput,
      navigationRequest: navigationRequest ?? this.navigationRequest,
    );
  }
}

class RegistrationCoreDetailsBloc
    extends Bloc<RegistrationCoreDetailsEvent, RegistrationCoreDetailsState> {
  RegistrationCoreDetailsBloc({
    required BaseProfileSetupRepository repository,
    required RegistrationCoreDetailsStep step,
  }) : _repository = repository,
       super(
         RegistrationCoreDetailsState(
           step: step,
           draft: repository.draft,
           dateOfBirthInput: _formatDateOfBirth(repository.draft.dateOfBirth),
         ),
       ) {
    on<RegistrationFirstNameChanged>(_onFirstNameChanged);
    on<RegistrationLastNameChanged>(_onLastNameChanged);
    on<RegistrationGenderSelected>(_onGenderSelected);
    on<RegistrationDateOfBirthChanged>(_onDateOfBirthChanged);
    on<RegistrationCoreDetailsContinueRequested>(_onContinueRequested);
  }

  final BaseProfileSetupRepository _repository;

  Future<void> _onFirstNameChanged(
    RegistrationFirstNameChanged event,
    Emitter<RegistrationCoreDetailsState> emit,
  ) async {
    final draft = state.draft.copyWith(firstName: event.value);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  Future<void> _onLastNameChanged(
    RegistrationLastNameChanged event,
    Emitter<RegistrationCoreDetailsState> emit,
  ) async {
    final draft = state.draft.copyWith(lastName: event.value);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  Future<void> _onGenderSelected(
    RegistrationGenderSelected event,
    Emitter<RegistrationCoreDetailsState> emit,
  ) async {
    if (state.step != RegistrationCoreDetailsStep.gender) {
      return;
    }
    final draft = state.draft.copyWith(gender: event.value);
    await _repository.saveDraft(draft);
    emit(
      state.copyWith(
        draft: draft,
        navigationRequest: state.navigationRequest + 1,
      ),
    );
  }

  Future<void> _onDateOfBirthChanged(
    RegistrationDateOfBirthChanged event,
    Emitter<RegistrationCoreDetailsState> emit,
  ) async {
    final parsed = _parseDateOfBirth(event.value);
    final draft = parsed == null
        ? state.draft
        : state.draft.copyWith(dateOfBirth: parsed);
    if (parsed != null) {
      await _repository.saveDraft(draft);
    }
    emit(state.copyWith(draft: draft, dateOfBirthInput: event.value));
  }

  Future<void> _onContinueRequested(
    RegistrationCoreDetailsContinueRequested event,
    Emitter<RegistrationCoreDetailsState> emit,
  ) async {
    if (!state.canContinue) {
      return;
    }
    await _repository.saveDraft(state.draft);
    emit(state.copyWith(navigationRequest: state.navigationRequest + 1));
  }
}

DateTime? _parseDateOfBirth(String input) {
  final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(input.trim());
  if (match == null) {
    return null;
  }
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

int _ageFor(DateTime dateOfBirth) {
  final today = DateTime.now();
  var age = today.year - dateOfBirth.year;
  if (today.month < dateOfBirth.month ||
      (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
    age -= 1;
  }
  return age;
}

String _formatDateOfBirth(DateTime? dateOfBirth) {
  if (dateOfBirth == null) {
    return '';
  }
  return '${dateOfBirth.day.toString().padLeft(2, '0')}.'
      '${dateOfBirth.month.toString().padLeft(2, '0')}.'
      '${dateOfBirth.year}';
}
