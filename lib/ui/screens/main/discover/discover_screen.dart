import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_bloc.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_event.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_state.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key, required BaseDiscoveryRepository repository})
    : _repository = repository;

  final BaseDiscoveryRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscoverScreenBloc>(
      create: (BuildContext context) =>
          DiscoverScreenBloc(repository: _repository)
            ..add(const DiscoverScreenLoadRequested()),
      child: const _DiscoverView(),
    );
  }
}

class _DiscoverView extends StatelessWidget {
  const _DiscoverView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Discover')),
      child: SafeArea(
        child: BlocBuilder<DiscoverScreenBloc, DiscoverScreenState>(
          builder: (BuildContext context, DiscoverScreenState state) {
            if (state is DiscoverScreenLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (state is DiscoverScreenFailure) {
              return const Center(
                child: Text('Unable to load placeholder profiles.'),
              );
            }

            final profiles = (state as DiscoverScreenLoaded).profiles;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final profile = profiles[index];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.firstName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(profile.headline),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
