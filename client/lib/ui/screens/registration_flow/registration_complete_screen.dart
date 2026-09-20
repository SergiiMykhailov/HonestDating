import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RegistrationCompleteScreen extends StatefulWidget {
  const RegistrationCompleteScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  State<RegistrationCompleteScreen> createState() =>
      _RegistrationCompleteScreenState();
}

class _RegistrationCompleteScreenState
    extends State<RegistrationCompleteScreen> {
  bool _isCompleting = true;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _completeRegistration();
  }

  Future<void> _completeRegistration() async {
    final isReady = widget.repository.draft.isRegistrationRequiredComplete;
    if (isReady && !widget.repository.isMobileRegistrationComplete) {
      await widget.repository.completeMobileRegistration();
    }
    if (mounted) {
      setState(() {
        _isReady = isReady;
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: 'Registration complete',
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 48),
              onPressed: () => Navigator.of(context).maybePop(),
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
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: _isCompleting
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          color: AppColors.coral,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          Center(
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: AppColors.coralSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox(
                                width: 112,
                                height: 112,
                                child: Icon(
                                  CupertinoIcons.check_mark_circled_solid,
                                  color: AppColors.coral,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _isReady
                                ? 'Registration Complete'
                                : 'Finish your registration',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 30,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isReady
                                ? 'Your Honest Dating account is ready. One thing to do next: make your profile more complete. Start by adding your interests. They help people discover you based on shared interests in Discover, help you target your Target Me posts more effectively, and allow you to receive Target Me posts targeted to your interests. There are 33 categories to explore, with a wide range of interests to choose from. You can add as many as you like, and you can always add more later. You can also add more photos and an About Me to give people a better sense of who you are. You don’t have to do everything now. You can add interests, photos, and your About Me whenever you have time.'
                                : 'Some required registration details are missing. Go back and complete them before starting.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.mutedInk,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const Spacer(),
                          if (_isReady) ...[
                            AppPrimaryButton(
                              label: 'Build Profile',
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(BaseRouter.profileBuilder);
                              },
                            ),
                            const SizedBox(height: 10),
                            CupertinoButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  BaseRouter.home,
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: const Text(
                                'Start Dating',
                                style: TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else
                            AppPrimaryButton(
                              label: 'Go back',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileBuilderScreen extends StatefulWidget {
  const ProfileBuilderScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  State<ProfileBuilderScreen> createState() => _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends State<ProfileBuilderScreen> {
  Future<void> _openBuilderTool(String route) async {
    await Navigator.of(context).pushNamed(route, arguments: true);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openGallery() async {
    await Navigator.of(context).pushNamed(BaseRouter.profileBuilderGallery);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.repository.draft;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: 'Build your profile',
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
                  const Text(
                    'Make it your own',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'These details are optional. You can add or change them later.',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _BuilderAction(
                    title: 'About Me',
                    detail: draft.aboutMe.trim().isEmpty
                        ? 'Add a short introduction'
                        : 'Saved',
                    onPressed: () =>
                        _openBuilderTool(BaseRouter.profileAboutMe),
                  ),
                  const SizedBox(height: 12),
                  _BuilderAction(
                    title: 'Interests',
                    detail: draft.interests.isEmpty
                        ? 'Add what you are into'
                        : '${draft.interests.length} saved',
                    onPressed: () =>
                        _openBuilderTool(BaseRouter.profileInterests),
                  ),
                  const SizedBox(height: 12),
                  _BuilderAction(
                    title: 'Gallery photos',
                    detail: draft.galleryPhotoPaths.isEmpty
                        ? 'Add up to 10 optional photos'
                        : '${draft.galleryPhotoPaths.length} of 10 selected',
                    onPressed: _openGallery,
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Start Dating',
                    onPressed: () =>
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          BaseRouter.home,
                          (Route<dynamic> route) => false,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileBuilderGalleryScreen extends StatefulWidget {
  const ProfileBuilderGalleryScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  State<ProfileBuilderGalleryScreen> createState() =>
      _ProfileBuilderGalleryScreenState();
}

class _ProfileBuilderGalleryScreenState
    extends State<ProfileBuilderGalleryScreen> {
  bool _isPicking = false;

  Future<void> _addPhotos() async {
    if (_isPicking) {
      return;
    }
    setState(() => _isPicking = true);
    try {
      final selected = await widget.repository.selectGalleryPhotos();
      final paths = <String>{
        ...widget.repository.draft.galleryPhotoPaths,
        ...selected,
      }..remove(widget.repository.draft.mainPhotoPath);
      await widget.repository.saveDraft(
        widget.repository.draft.copyWith(
          galleryPhotoPaths: paths.take(10).toList(),
        ),
      );
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _removePhoto(String path) async {
    await widget.repository.saveDraft(
      widget.repository.draft.copyWith(
        galleryPhotoPaths: widget.repository.draft.galleryPhotoPaths
            .where((String existing) => existing != path)
            .toList(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.repository.draft.galleryPhotoPaths;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: 'Gallery photos',
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
                  const Text(
                    'Add more photos',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gallery photos are optional. You can select up to 10 on this device.',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (paths.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: paths
                          .map(
                            (String path) => _GalleryTile(
                              path: path,
                              onRemove: () => _removePhoto(path),
                            ),
                          )
                          .toList(),
                    ),
                  if (paths.isNotEmpty) const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: paths.length >= 10
                        ? 'Gallery is full'
                        : 'Add photos',
                    isLoading: _isPicking,
                    onPressed: paths.length >= 10 ? null : _addPhotos,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuilderAction extends StatelessWidget {
  const _BuilderAction({
    required this.title,
    required this.detail,
    required this.onPressed,
  });

  final String title;
  final String detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                style: const TextStyle(color: AppColors.mutedInk, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            width: 94,
            height: 94,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 94,
              height: 94,
              child: ColoredBox(color: AppColors.softCanvas),
            ),
          ),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            onPressed: onRemove,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.coral,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
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
