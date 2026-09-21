import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/interest_catalog.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration_flow/bloc/interest_catalog_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class InterestCatalogPickerArguments {
  const InterestCatalogPickerArguments({this.categoryID});

  final String? categoryID;
}

class InterestCategoriesScreen extends StatelessWidget {
  const InterestCategoriesScreen({
    super.key,
    required BaseProfileSetupRepository repository,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InterestCatalogBloc>(
      create: (BuildContext context) =>
          InterestCatalogBloc(repository: _repository),
      child: const _InterestCategoriesView(),
    );
  }
}

class _InterestCategoriesView extends StatefulWidget {
  const _InterestCategoriesView();

  @override
  State<_InterestCategoriesView> createState() =>
      _InterestCategoriesViewState();
}

class _InterestCategoriesViewState extends State<_InterestCategoriesView> {
  Future<void> _openPicker(String? categoryID) async {
    await Navigator.of(context).pushNamed(
      BaseRouter.registrationInterestPicker,
      arguments: InterestCatalogPickerArguments(categoryID: categoryID),
    );
    if (mounted) {
      context.read<InterestCatalogBloc>().add(const InterestCatalogReloaded());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocBuilder<InterestCatalogBloc, InterestCatalogState>(
        builder: (BuildContext context, InterestCatalogState state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Interests',
                leading: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    children: [
                      Text(
                        'Choose at least 5 interests',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${state.draft.interests.length} selected. Explore one of 33 categories or search every available interest.',
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _TextAction(
                        label: 'Search all interests',
                        onPressed: () => _openPicker(null),
                      ),
                      if (state.draft.interests.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SelectedInterests(
                          interests: state.draft.interests,
                          onRemove: (String interest) {
                            context.read<InterestCatalogBloc>().add(
                              InterestCatalogInterestRemoved(interest),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 26),
                      const Text(
                        'Explore categories',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...interestCategories.map(
                        (InterestCategory category) => _TextAction(
                          label: '${category.icon}  ${category.label}',
                          onPressed: () => _openPicker(category.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class InterestCatalogPickerScreen extends StatelessWidget {
  const InterestCatalogPickerScreen({
    super.key,
    required BaseProfileSetupRepository repository,
    required this.arguments,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;
  final InterestCatalogPickerArguments arguments;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InterestCatalogBloc>(
      create: (BuildContext context) =>
          InterestCatalogBloc(repository: _repository),
      child: _InterestCatalogPickerView(arguments: arguments),
    );
  }
}

class _InterestCatalogPickerView extends StatefulWidget {
  const _InterestCatalogPickerView({required this.arguments});

  final InterestCatalogPickerArguments arguments;

  @override
  State<_InterestCatalogPickerView> createState() =>
      _InterestCatalogPickerViewState();
}

class _InterestCatalogPickerViewState
    extends State<_InterestCatalogPickerView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryID = widget.arguments.categoryID;
    final category = categoryID == null
        ? null
        : interestCategories.firstWhere(
            (InterestCategory value) => value.id == categoryID,
          );
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocBuilder<InterestCatalogBloc, InterestCatalogState>(
        builder: (BuildContext context, InterestCatalogState state) {
          final interests = category == null
              ? searchCatalogInterests(state.query)
              : interestsForCategory(category.id).where((String interest) {
                  return interest.toLowerCase().contains(
                    state.query.trim().toLowerCase(),
                  );
                }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: category == null ? 'Search interests' : category.label,
                leading: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    children: [
                      Text(
                        category == null
                            ? 'What interests you?'
                            : '${category.icon} ${category.label}',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Search and select as many interests as you like.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppFormField(
                        label: 'Search interests',
                        placeholder: 'For example, hiking',
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (String value) {
                          context.read<InterestCatalogBloc>().add(
                            InterestCatalogQueryChanged(value),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      if (interests.isEmpty)
                        const Text(
                          'No matching interests yet.',
                          style: TextStyle(color: AppColors.mutedInk),
                        )
                      else
                        ...interests.map(
                          (String interest) => _InterestToggle(
                            interest: interest,
                            isSelected: state.draft.interests.contains(
                              interest,
                            ),
                            onPressed: () {
                              context.read<InterestCatalogBloc>().add(
                                InterestCatalogInterestToggled(interest),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        label: 'Save and return',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 10),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: AppColors.coral,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InterestToggle extends StatelessWidget {
  const _InterestToggle({
    required this.interest,
    required this.isSelected,
    required this.onPressed,
  });

  final String interest;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CupertinoSwitch(
                    value: isSelected,
                    activeTrackColor: AppColors.coral,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedInterests extends StatelessWidget {
  const _SelectedInterests({required this.interests, required this.onRemove});

  final List<String> interests;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests
          .map(
            (String interest) => DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interest,
                      style: const TextStyle(
                        color: AppColors.plum,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(5),
                      minimumSize: const Size(28, 28),
                      onPressed: () => onRemove(interest),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: AppColors.plum,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(48, 48),
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.coral,
            size: 21,
          ),
        ),
      ),
    );
  }
}
