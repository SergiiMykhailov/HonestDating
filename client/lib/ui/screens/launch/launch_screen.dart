import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';

/// Resolves a restored Firebase session before showing either the welcome
/// screen or the signed-in application shell.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.accountRepository});

  final BaseAuthenticatedAccountRepository accountRepository;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    var hasCompletedRegistration = false;
    try {
      hasCompletedRegistration = await widget.accountRepository
          .hasCompletedMobileRegistration();
    } catch (_) {
      // A failed startup lookup must never expose a stale signed-in surface.
      hasCompletedRegistration = false;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      hasCompletedRegistration ? BaseRouter.home : BaseRouter.onboarding,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: AppColors.navy,
      child: Center(
        child: CupertinoActivityIndicator(color: AppColors.canvas, radius: 13),
      ),
    );
  }
}
