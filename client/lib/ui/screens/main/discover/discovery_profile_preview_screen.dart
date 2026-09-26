import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

/// Read-only profile foundation for Slice 1. Relationship indicators and
/// connection actions are introduced in the following profile slice.
class DiscoveryProfilePreviewScreen extends StatelessWidget {
  const DiscoveryProfilePreviewScreen({super.key, required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        children: [
          AppNavigationBar(
            title: 'Profile',
            leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  AspectRatio(
                    aspectRatio: 0.82,
                    child: Image.asset(
                      profile.primaryPhotoAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(26, 30, 26, 8),
                      decoration: const BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.firstName}, ${profile.age}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 30),
                          const Text(
                            'About',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            profile.headline,
                            style: const TextStyle(
                              color: AppColors.mutedInk,
                              fontSize: 17,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
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
