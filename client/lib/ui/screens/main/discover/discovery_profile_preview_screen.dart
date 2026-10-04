import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discovery_profile_bloc.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discovery_profile_event.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discovery_profile_state.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class DiscoveryProfilePreviewScreen extends StatelessWidget {
  const DiscoveryProfilePreviewScreen({
    super.key,
    required this.profile,
    required BaseDiscoveryRepository repository,
  }) : _repository = repository;

  final DiscoveryProfile profile;
  final BaseDiscoveryRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscoveryProfileBloc>(
      create: (BuildContext context) =>
          DiscoveryProfileBloc(repository: _repository, initialProfile: profile)
            ..add(const DiscoveryProfileRefreshRequested()),
      child: const _DiscoveryProfileView(),
    );
  }
}

class _DiscoveryProfileView extends StatelessWidget {
  const _DiscoveryProfileView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocBuilder<DiscoveryProfileBloc, DiscoveryProfileState>(
        builder: (BuildContext context, DiscoveryProfileState state) {
          final profile = state.profile;
          return Column(
            children: [
              AppNavigationBar(
                title: 'Profile',
                leading: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      AspectRatio(
                        aspectRatio: 0.86,
                        child: Image.network(
                          profile.primaryPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: AppColors.softCanvas),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: _ProfileSheet(
                          state: state,
                          onLikePressed: () => _requestLike(context),
                          onFriendshipPressed: () =>
                              _handleFriendshipPressed(context),
                          onQuestionsPressed: () {
                            Navigator.of(context).pushNamed(
                              BaseRouter.discoveryQuestions,
                              arguments: profile,
                            );
                          },
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

  Future<void> _requestLike(BuildContext context) async {
    final reason = await _requestReason(
      context,
      title: 'Send a Like',
      prompt: 'What caught your attention about this person?',
      submitLabel: 'Send Like',
    );
    if (context.mounted && reason != null) {
      context.read<DiscoveryProfileBloc>().add(
        DiscoveryProfileLikeSubmitted(reason),
      );
    }
  }

  Future<void> _handleFriendshipPressed(BuildContext context) async {
    final relationship = context
        .read<DiscoveryProfileBloc>()
        .state
        .profile
        .relationship;
    if (relationship.friendship == DiscoveryFriendshipState.offerReceived) {
      context.read<DiscoveryProfileBloc>().add(
        const DiscoveryProfileFriendshipOfferAccepted(),
      );
      return;
    }

    final reason = await _requestReason(
      context,
      title: 'Offer friendship',
      prompt: 'Why would you genuinely enjoy getting to know this person?',
      submitLabel: 'Send offer',
    );
    if (context.mounted && reason != null) {
      context.read<DiscoveryProfileBloc>().add(
        DiscoveryProfileFriendshipOfferSubmitted(reason),
      );
    }
  }

  Future<String?> _requestReason(
    BuildContext context, {
    required String title,
    required String prompt,
    required String submitLabel,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return _ConnectionReasonSheet(
          title: title,
          prompt: prompt,
          submitLabel: submitLabel,
        );
      },
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.state,
    required this.onLikePressed,
    required this.onFriendshipPressed,
    required this.onQuestionsPressed,
  });

  final DiscoveryProfileState state;
  final VoidCallback onLikePressed;
  final VoidCallback onFriendshipPressed;
  final VoidCallback onQuestionsPressed;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final relationship = profile.relationship;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 160),
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.firstName}, ${profile.age}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_solid,
                    color: AppColors.coral,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${profile.distanceMiles} ${profile.distanceMiles == 1 ? 'mile' : 'miles'} away · ${profile.locationLabel}',
                      style: const TextStyle(
                        color: AppColors.mutedInk,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _RelationshipSummary(relationship: relationship),
              if (relationship.romantic == DiscoveryRomanticState.matched) ...[
                if (relationship.incomingLikeReason
                    case final String reason) ...[
                  const SizedBox(height: 18),
                  _ReasonCard(
                    title: 'Why ${profile.firstName} liked you',
                    message: reason,
                  ),
                ],
                if (relationship.outgoingLikeReason
                    case final String reason) ...[
                  const SizedBox(height: 12),
                  _ReasonCard(
                    title: 'Why you liked ${profile.firstName}',
                    message: reason,
                  ),
                ],
              ],
              if (relationship.incomingFriendshipReason
                  case final String reason) ...[
                const SizedBox(height: 18),
                _ReasonCard(
                  title: '${profile.firstName}’s friendship offer',
                  message: reason,
                ),
              ],
              if (state.feedbackMessage case final String message) ...[
                const SizedBox(height: 18),
                _ActionFeedback(
                  message: message,
                  isError: state.feedbackIsError,
                  onDismiss: () {
                    context.read<DiscoveryProfileBloc>().add(
                      const DiscoveryProfileFeedbackDismissed(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              const _SectionTitle('About'),
              const SizedBox(height: 10),
              Text(
                profile.headline,
                style: const TextStyle(
                  color: AppColors.mutedInk,
                  fontSize: 17,
                  height: 1.45,
                ),
              ),
              if (profile.details.isNotEmpty) ...[
                const SizedBox(height: 32),
                const _SectionTitle('Basic info'),
                const SizedBox(height: 14),
                _ProfileDetails(details: profile.details),
              ],
              if (profile.interests.isNotEmpty) ...[
                const SizedBox(height: 32),
                const _SectionTitle('Interests'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests
                      .map((String interest) => _InterestChip(label: interest))
                      .toList(),
                ),
              ],
              const SizedBox(height: 32),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onQuestionsPressed,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.softCanvas,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100 Questions for Us',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Get to know each other beyond the basics',
                                style: TextStyle(
                                  color: AppColors.mutedInk,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: AppColors.coral,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (profile.galleryPhotoUrls.isNotEmpty) ...[
                const SizedBox(height: 32),
                const _SectionTitle('Gallery'),
                const SizedBox(height: 14),
                _ProfileGallery(urls: profile.galleryPhotoUrls),
              ],
            ],
          ),
        ),
        Positioned(
          top: -34,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundConnectionAction(
                semanticLabel: _friendshipActionLabel(relationship),
                icon: _friendshipIcon(relationship),
                color: AppColors.plum,
                isAvailable: _canUseFriendshipAction(relationship),
                isLoading: state.isSubmitting,
                onPressed: onFriendshipPressed,
              ),
              const SizedBox(width: 16),
              _RoundConnectionAction(
                semanticLabel: _romanticActionLabel(relationship),
                icon: _romanticIcon(relationship),
                color: AppColors.coral,
                isAvailable: _canUseRomanticAction(relationship),
                isLoading: state.isSubmitting,
                onPressed: onLikePressed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canUseRomanticAction(DiscoveryRelationship relationship) {
    return relationship.friendship == DiscoveryFriendshipState.none &&
        (relationship.romantic == DiscoveryRomanticState.none ||
            relationship.romantic == DiscoveryRomanticState.likeReceived);
  }

  bool _canUseFriendshipAction(DiscoveryRelationship relationship) {
    return relationship.friendship == DiscoveryFriendshipState.none ||
        relationship.friendship == DiscoveryFriendshipState.offerReceived;
  }

  IconData _romanticIcon(DiscoveryRelationship relationship) {
    return switch (relationship.romantic) {
      DiscoveryRomanticState.none => CupertinoIcons.heart_fill,
      DiscoveryRomanticState.likeReceived => CupertinoIcons.heart_fill,
      DiscoveryRomanticState.likeSent => CupertinoIcons.heart_fill,
      DiscoveryRomanticState.matched => CupertinoIcons.heart_fill,
      DiscoveryRomanticState.unavailable => CupertinoIcons.heart_slash,
    };
  }

  IconData _friendshipIcon(DiscoveryRelationship relationship) {
    return switch (relationship.friendship) {
      DiscoveryFriendshipState.none => CupertinoIcons.person_2_fill,
      DiscoveryFriendshipState.offerSent => CupertinoIcons.person_2_fill,
      DiscoveryFriendshipState.offerReceived => CupertinoIcons.person_2_fill,
      DiscoveryFriendshipState.friends => CupertinoIcons.person_2_fill,
    };
  }

  String _romanticActionLabel(DiscoveryRelationship relationship) {
    return switch (relationship.romantic) {
      DiscoveryRomanticState.none => 'Send Like',
      DiscoveryRomanticState.likeReceived => 'Like back',
      DiscoveryRomanticState.likeSent => 'Like sent',
      DiscoveryRomanticState.matched => 'Matched',
      DiscoveryRomanticState.unavailable => 'Romantic interest unavailable',
    };
  }

  String _friendshipActionLabel(DiscoveryRelationship relationship) {
    return switch (relationship.friendship) {
      DiscoveryFriendshipState.none => 'Offer friendship',
      DiscoveryFriendshipState.offerSent => 'Friendship offer sent',
      DiscoveryFriendshipState.offerReceived => 'Accept friendship offer',
      DiscoveryFriendshipState.friends => 'Friends',
    };
  }
}

class _RoundConnectionAction extends StatelessWidget {
  const _RoundConnectionAction({
    required this.semanticLabel,
    required this.icon,
    required this.color,
    required this.isAvailable,
    required this.isLoading,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(68, 68),
        onPressed: isAvailable && !isLoading ? onPressed : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            shape: BoxShape.circle,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SizedBox(
            width: 68,
            height: 68,
            child: Center(
              child: isLoading
                  ? const CupertinoActivityIndicator(color: AppColors.coral)
                  : Icon(
                      icon,
                      color: isAvailable ? color : AppColors.line,
                      size: 31,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipSummary extends StatelessWidget {
  const _RelationshipSummary({required this.relationship});

  final DiscoveryRelationship relationship;

  @override
  Widget build(BuildContext context) {
    final message = _messageFor(relationship);
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.coral,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String? _messageFor(DiscoveryRelationship relationship) {
    if (relationship.friendship == DiscoveryFriendshipState.offerReceived) {
      return 'Friendship offer received';
    }
    if (relationship.friendship == DiscoveryFriendshipState.offerSent) {
      return 'Friendship offer sent';
    }
    if (relationship.friendship == DiscoveryFriendshipState.friends) {
      return 'Friends';
    }
    return switch (relationship.romantic) {
      DiscoveryRomanticState.none => null,
      DiscoveryRomanticState.likeSent => 'Like sent',
      DiscoveryRomanticState.likeReceived => 'They like you',
      DiscoveryRomanticState.matched => 'Matched',
      DiscoveryRomanticState.unavailable => 'Romantic interest unavailable',
    };
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.mutedInk,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionFeedback extends StatelessWidget {
  const _ActionFeedback({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.coral : AppColors.plum;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: isError ? AppColors.coralSoft : const Color(0xFFF6ECF7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle
                  : CupertinoIcons.check_mark_circled,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(34, 34),
              onPressed: onDismiss,
              child: Icon(CupertinoIcons.xmark, color: color, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.details});

  final List<DiscoveryProfileDetail> details;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softCanvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: details
              .map(
                (DiscoveryProfileDetail detail) => _ProfileDetailRow(
                  detail: detail,
                  isLast: detail == details.last,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({required this.detail, required this.isLast});

  final DiscoveryProfileDetail detail;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              detail.label,
              style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              detail.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.plum,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileGallery extends StatelessWidget {
  const _ProfileGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (BuildContext context, int index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            urls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.softCanvas),
          ),
        );
      },
    );
  }
}

class _ConnectionReasonSheet extends StatefulWidget {
  const _ConnectionReasonSheet({
    required this.title,
    required this.prompt,
    required this.submitLabel,
  });

  final String title;
  final String prompt;
  final String submitLabel;

  @override
  State<_ConnectionReasonSheet> createState() => _ConnectionReasonSheetState();
}

class _ConnectionReasonSheetState extends State<_ConnectionReasonSheet> {
  final TextEditingController _controller = TextEditingController();

  bool get _isValid {
    final length = _controller.text.trim().length;
    return length >= 50 && length <= 500;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.trim().length;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.prompt,
              style: const TextStyle(
                color: AppColors.mutedInk,
                fontSize: 16,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoTextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              placeholder: 'Write in your own words…',
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$length / 500 characters · minimum 50',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: length >= 50 ? AppColors.mutedInk : AppColors.coral,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: widget.submitLabel,
              onPressed: _isValid
                  ? () => Navigator.of(context).pop(_controller.text.trim())
                  : null,
            ),
            const SizedBox(height: 4),
            CupertinoButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.coral,
            size: 24,
          ),
        ),
      ),
    );
  }
}
